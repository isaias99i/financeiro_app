class InvoiceInstallmentInfo {
  final int index;
  final int count;

  // Representa a parcela atual e o total de parcelas.
  const InvoiceInstallmentInfo({
    required this.index,
    required this.count,
  });
}

class InvoiceParsedItem {
  final DateTime date;
  final String description;
  final double amount;
  final InvoiceInstallmentInfo? installment;

  // Item parseado da fatura (data, descricao, valor).
  const InvoiceParsedItem({
    required this.date,
    required this.description,
    required this.amount,
    this.installment,
  });
}

class InvoiceParser {
  static final RegExp _dateNumeric =
      RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?\b');
  static final RegExp _datePt = RegExp(
    r'\b(\d{1,2})\s+de\s+([a-zA-Z\.]+)\s+(\d{4})\b',
    caseSensitive: false,
  );
  static final RegExp _datePtShort = RegExp(
    r'\b(\d{1,2})\s+([a-zA-Z]{3,})\b',
    caseSensitive: false,
  );
  static final RegExp _amountRegex =
      RegExp(r'([+\-]?)\s*R?\$?\s*(-?\d{1,3}(?:\.\d{3})*,\d{2})');
  static final RegExp _installmentSlash =
      RegExp(r'\b(\d{1,2})\s*\/\s*(\d{1,2})\b');
  static final RegExp _installmentWord =
      RegExp(r'\b(\d{1,2})\s+de\s+(\d{1,2})\b');

  static const Map<String, int> _ptMonths = {
    'jan': 1,
    'janeiro': 1,
    'fev': 2,
    'fevereiro': 2,
    'mar': 3,
    'marco': 3,
    'abr': 4,
    'abril': 4,
    'mai': 5,
    'maio': 5,
    'jun': 6,
    'junho': 6,
    'jul': 7,
    'julho': 7,
    'ago': 8,
    'agosto': 8,
    'set': 9,
    'setembro': 9,
    'out': 10,
    'outubro': 10,
    'nov': 11,
    'novembro': 11,
    'dez': 12,
    'dezembro': 12,
  };

  static List<InvoiceParsedItem> parse(
    String text, {
    required DateTime referenceDate,
    void Function(String message)? debugLog,
  }) {
    // Faz parsing linha a linha com suporte a multiline (descricao + valor).
    final lines = _normalizeLines(text);
    if (_looksLikeSantander(lines)) {
      debugLog?.call('PARSE_PROFILE: santander');
      return _parseSantander(lines, referenceDate, debugLog);
    }
    return _parseGeneric(lines, referenceDate, debugLog);
  }

  static List<String> _normalizeLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _normalizeLine(String line) {
    // Normaliza texto para comparacoes sem acento.
    final lower = line.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(_diacriticMap[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Map<int, String> _diacriticMap = {
    0x00e1: 'a',
    0x00e0: 'a',
    0x00e2: 'a',
    0x00e3: 'a',
    0x00e4: 'a',
    0x00e9: 'e',
    0x00e8: 'e',
    0x00ea: 'e',
    0x00eb: 'e',
    0x00ed: 'i',
    0x00ec: 'i',
    0x00ee: 'i',
    0x00ef: 'i',
    0x00f3: 'o',
    0x00f2: 'o',
    0x00f4: 'o',
    0x00f5: 'o',
    0x00f6: 'o',
    0x00fa: 'u',
    0x00f9: 'u',
    0x00fb: 'u',
    0x00fc: 'u',
    0x00e7: 'c',
  };

  static bool _looksLikeSantander(List<String> lines) {
    final sample = _normalizeLine(lines.take(80).join(' '));
    return sample.contains('detalhamento da fatura') ||
        sample.contains('pagamento e demais creditos') ||
        sample.contains('parcelamentos');
  }

  static List<InvoiceParsedItem> _parseGeneric(
    List<String> lines,
    DateTime referenceDate,
    void Function(String message)? debugLog,
  ) {
    final results = <InvoiceParsedItem>[];
    DateTime? currentDate;
    String? currentDescription;
    InvoiceInstallmentInfo? currentInstallment;
    final pendingParts = <String>[];

    // Some PDFs split "date/description" and "amount" across different lines.
    for (final line in lines) {
      debugLog?.call('OCR: "$line"');
      if (_shouldSkip(line, currentDate != null)) {
        continue;
      }
      final date = _parseDate(line, referenceDate);
      if (date != null) {
        currentDate = date;
        currentInstallment = _parseInstallment(line);
        final inline = _extractDescription(line, date, currentInstallment);
        currentDescription = inline.isNotEmpty
            ? inline
            : (pendingParts.isNotEmpty ? pendingParts.join(' ') : null);
        pendingParts.clear();
      }

      final amount = _parseAmount(line);
      if (currentDate != null && amount != null) {
        if (_shouldDeferAmountLine(line)) {
          continue;
        }
        currentInstallment ??= _parseInstallment(line);
        var description = currentDescription ?? '';
        if (description.isEmpty) {
          if (pendingParts.isNotEmpty) {
            description = pendingParts.join(' ');
          } else {
            description = _stripAmount(line);
          }
        }
        if (description.isEmpty) {
          description = 'Lancamento';
        }
        description = _stripAmount(description);
        debugLog?.call('PARSED: "$description" | $amount');
        results.add(
          InvoiceParsedItem(
            date: currentDate,
            description: description,
            amount: amount,
            installment: currentInstallment,
          ),
        );
        currentDate = null;
        currentDescription = null;
        currentInstallment = null;
        pendingParts.clear();
        continue;
      }

      if (date == null && amount == null) {
        if (currentDate != null && currentInstallment == null) {
          currentInstallment = _parseInstallment(line);
        }
        if (currentDate != null &&
            (currentDescription == null || currentDescription.isEmpty)) {
          if (!_isCardMaskLine(line)) {
            pendingParts.add(line);
          }
        }
      }
    }
    return results;
  }

  static List<InvoiceParsedItem> _parseSantander(
    List<String> lines,
    DateTime referenceDate,
    void Function(String message)? debugLog,
  ) {
    final tableLines = _santanderTableLines(lines);
    final results = <InvoiceParsedItem>[];
    DateTime? currentDate;
    String? currentDescription;
    InvoiceInstallmentInfo? currentInstallment;
    final pendingParts = <String>[];

    for (final line in tableLines) {
      debugLog?.call('OCR: "$line"');
      if (_shouldSkipSantander(line, currentDate != null)) {
        continue;
      }
      final date = currentDate == null ? _parseSantanderDate(line, referenceDate) : null;
      if (date != null) {
        currentDate = date;
        currentInstallment = null;
        final inline = _extractDescriptionSantander(line);
        currentDescription = inline.isNotEmpty
            ? inline
            : (pendingParts.isNotEmpty ? pendingParts.join(' ') : null);
        pendingParts.clear();
      }

      final amount = _parseAmount(line);
      if (currentDate != null && amount != null) {
        if (_shouldDeferAmountLine(line)) {
          continue;
        }
        currentInstallment ??= _parseInstallment(line);
        var description = currentDescription ?? '';
        if (description.isEmpty) {
          if (pendingParts.isNotEmpty) {
            description = pendingParts.join(' ');
          } else {
            description = _stripAmount(line);
          }
        }
        if (description.isEmpty) {
          description = 'Lancamento';
        }
        description = _stripAmount(description);
        debugLog?.call('PARSED: "$description" | $amount');
        results.add(
          InvoiceParsedItem(
            date: currentDate,
            description: description,
            amount: amount,
            installment: currentInstallment,
          ),
        );
        currentDate = null;
        currentDescription = null;
        currentInstallment = null;
        pendingParts.clear();
        continue;
      }

      if (date == null && amount == null) {
        final installment = _parseInstallment(line);
        if (currentDate != null && installment != null) {
          currentInstallment ??= installment;
          continue;
        }
        if (currentDate != null &&
            (currentDescription == null || currentDescription.isEmpty)) {
          if (!_isCardMaskLine(line) && !_isSantanderDetailLine(line)) {
            pendingParts.add(line);
          }
        }
      }
    }
    return results;
  }

  static List<String> _santanderTableLines(List<String> lines) {
    final filtered = <String>[];
    var inDetails = false;
    var inTable = false;
    for (final line in lines) {
      final normalized = _normalizeLine(line);
      if (normalized.contains('detalhamento da fatura')) {
        inDetails = true;
        inTable = false;
        continue;
      }
      if (!inDetails) continue;
      if (normalized.contains('resumo da fatura')) {
        break;
      }
      if (normalized.contains('pagamento e demais creditos') ||
          normalized.contains('parcelamentos')) {
        inTable = true;
        continue;
      }
      if (!inTable) continue;
      if (_isSantanderHeaderLine(line) || _isSantanderTableSeparator(line)) {
        continue;
      }
      filtered.add(line);
    }
    return filtered;
  }

  static bool _isSantanderHeaderLine(String line) {
    final normalized = _normalizeLine(line);
    if (normalized == 'compra' ||
        normalized == 'data' ||
        normalized == 'descricao' ||
        normalized == 'parcela' ||
        normalized == 'r\$' ||
        normalized == 'us\$') {
      return true;
    }
    if (normalized.contains('valor total')) return true;
    return false;
  }

  static bool _isSantanderTableSeparator(String line) {
    final normalized = _normalizeLine(line);
    if (normalized.startsWith('@ ') && normalized.contains('xxxx')) {
      return true;
    }
    return false;
  }

  static DateTime? _parseSantanderDate(String line, DateTime referenceDate) {
    // Datas Santander aparecem como DD/MM sem ano na coluna de compra.
    final normalized = _normalizeLine(line);
    if (normalized.contains('parcela') || normalized.contains('parc')) {
      return null;
    }
    final match = _dateNumeric.firstMatch(line);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    if (day == null || month == null) return null;
    final yearRaw = match.group(3);
    int year;
    if (yearRaw == null || yearRaw.isEmpty) {
      year = referenceDate.year;
      if (month > referenceDate.month + 1) {
        year -= 1;
      }
    } else {
      year = int.tryParse(yearRaw) ?? referenceDate.year;
      if (yearRaw.length == 2) {
        year += 2000;
      }
    }
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static bool _shouldSkipSantander(String line, bool hasCurrentDate) {
    final normalized = _normalizeLine(line);
    final hasAmount = _amountRegex.hasMatch(line);
    if (normalized.contains('valor total')) return true;
    if (!hasCurrentDate && normalized.startsWith('total ')) return true;
    if (!hasAmount && _isSantanderDetailLine(line)) {
      return true;
    }
    return false;
  }

  static bool _isSantanderDetailLine(String line) {
    final normalized = _normalizeLine(line);
    return normalized.contains('principal') || normalized.contains('juros');
  }

  static String _extractDescriptionSantander(String line) {
    final columns = _splitColumns(line);
    if (columns.length >= 3) {
      final slice = columns.sublist(1, columns.length - 1).join(' ');
      return _stripAmount(slice);
    }
    return _stripAmount(line);
  }

  static DateTime? _parseDate(String line, DateTime referenceDate) {
    // Tenta data numerica e data PT-BR (ex.: 12 de nov. 2025).
    return _parseNumericDate(line, referenceDate) ??
        _parsePtDate(line) ??
        _parsePtShortDate(line, referenceDate);
  }

  static DateTime? _parseNumericDate(String line, DateTime referenceDate) {
    // Datas no formato 12/11/2025 ou 12-11-25.
    final match = _dateNumeric.firstMatch(line);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    if (day == null || month == null) return null;
    final yearRaw = match.group(3);
    if (yearRaw == null || yearRaw.isEmpty) {
      final installmentMatch = _installmentSlash.firstMatch(line);
      if (installmentMatch != null) {
        final instDay = int.tryParse(installmentMatch.group(1) ?? '');
        final instMonth = int.tryParse(installmentMatch.group(2) ?? '');
        if (instDay == day && instMonth == month) {
          return null;
        }
      }
    }
    int year;
    if (yearRaw == null || yearRaw.isEmpty) {
      year = referenceDate.year;
      if (month > referenceDate.month + 1) {
        year -= 1;
      }
    } else {
      year = int.tryParse(yearRaw) ?? referenceDate.year;
      if (yearRaw.length == 2) {
        year += 2000;
      }
    }
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parsePtDate(String line) {
    // Datas PT-BR com mes abreviado ou por extenso.
    final match = _datePt.firstMatch(line);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    var monthToken = match.group(2) ?? '';
    monthToken = _normalizeLine(monthToken).replaceAll('.', '');
    final month = _ptMonths[monthToken];
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parsePtShortDate(String line, DateTime referenceDate) {
    // Datas PT-BR sem ano (ex.: 06 DEZ).
    final match = _datePtShort.firstMatch(line);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    var monthToken = match.group(2) ?? '';
    monthToken = _normalizeLine(monthToken).replaceAll('.', '');
    final month = _ptMonths[monthToken];
    if (day == null || month == null) return null;
    var year = referenceDate.year;
    if (month > referenceDate.month + 1) {
      year -= 1;
    }
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static double? _parseAmount(String line) {
    // Extrai valor monetario, respeitando sinais + e -.
    final normalizedLine = line
        .replaceAll('\u2212', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u00a0', ' ');
    final matches = _amountRegex.allMatches(normalizedLine).toList();
    if (matches.isEmpty) return null;
    final match = matches.last;
    final sign = match.group(1) ?? '';
    final raw = match.group(2) ?? '';
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    var isNegative = sign.contains('-') || raw.trim().startsWith('-');
    final hasExplicit = sign.contains('-') || sign.contains('+');
    if (!hasExplicit) {
      final after = normalizedLine.substring(match.end).trimLeft();
      final before = normalizedLine.substring(0, match.start).trimRight();
      final afterSign = after.startsWith('-')
          ? '-'
          : after.startsWith('+')
              ? '+'
              : null;
      final beforeSign = before.endsWith('-')
          ? '-'
          : before.endsWith('+')
              ? '+'
              : null;
      final inferred = afterSign ?? beforeSign;
      if (inferred == '-') {
        isNegative = true;
      } else if (inferred == '+') {
        isNegative = false;
      }
    }
    if (!hasExplicit && !isNegative) {
      // Faturas de cartao tendem a ser debito quando nao ha sinal explicito.
      return -value;
    }
    return isNegative ? -value : value;
  }

  static InvoiceInstallmentInfo? _parseInstallment(String line) {
    // Captura padroes de parcela como "01/12" ou "01 de 12".
    final match = _installmentSlash.firstMatch(line) ?? _installmentWord.firstMatch(line);
    if (match == null) return null;
    final index = int.tryParse(match.group(1) ?? '');
    final count = int.tryParse(match.group(2) ?? '');
    if (index == null || count == null || index <= 0 || count <= 1) {
      return null;
    }
    return InvoiceInstallmentInfo(index: index, count: count);
  }

  static String _extractDescription(
    String line,
    DateTime date,
    InvoiceInstallmentInfo? installment,
  ) {
    // Usa a segunda coluna quando o PDF vem em colunas.
    final columns = _splitColumns(line);
    if (columns.length >= 2) {
      return _stripAmount(columns[1]);
    }
    return _stripAmount(line);
  }

  static String _stripAmount(String line) {
    // Remove data e valor para restar somente a descricao.
    var cleaned = line;
    cleaned = cleaned.replaceFirst(_dateNumeric, '');
    cleaned = cleaned.replaceFirst(_datePt, '');
    cleaned = cleaned.replaceFirst(_datePtShort, '');
    cleaned = cleaned.replaceFirst(_amountRegex, '');
    cleaned = cleaned.replaceAll(RegExp(r'[-+]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+[-+]\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]{2,}\s*\d{2,4}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]{2,}'), '');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _shouldDeferAmountLine(String line) {
    final normalized = _normalizeLine(line);
    if (normalized.contains('total a pagar') &&
        !normalized.contains('parcelad') &&
        !normalized.contains('vezes')) {
      return true;
    }
    return false;
  }

  static bool _isCardMaskLine(String line) {
    final trimmed = line.trim();
    return RegExp(r'^[^\w\s]{2,}\s*\d{2,4}$').hasMatch(trimmed);
  }

  static bool _shouldSkip(String line, bool hasCurrentDate) {
    // Ignora cabecalhos e linhas que nao sao lancamentos.
    final normalized = _normalizeLine(line);
    if (normalized.startsWith('data movimentacao')) return true;
    if (normalized.contains('total cartao')) return true;
    if (!hasCurrentDate && normalized.startsWith('total ')) return true;
    if (normalized.contains('principal') || normalized.contains('juros')) {
      return true;
    }
    return false;
  }

  static List<String> _splitColumns(String line) {
    // PDFs costumam separar colunas com espacos duplos.
    return line.split(RegExp(r'\s{2,}')).where((part) => part.trim().isNotEmpty).toList();
  }

  static String inferCategory(String description, List<String> categories) {
    final normalized = _normalizeLine(description);
    for (final category in categories) {
      if (category.trim().isEmpty) continue;
      final name = _normalizeLine(category);
      if (normalized.contains(name)) {
        return category;
      }
    }

    final mapping = <String, List<String>>{
      'Alimentacao': ['restaurante', 'lanch', 'padaria', 'super', 'mercado', 'ifood'],
      'Transporte': ['uber', '99', 'gasolina', 'combust', 'metro', 'onibus', 'posto'],
      'Saude': ['farmacia', 'drogaria', 'clinica', 'medic', 'hospital', 'laboratorio'],
      'Educacao': ['escola', 'curso', 'faculdade', 'universidade', 'livro'],
      'Lazer': ['cinema', 'stream', 'spotify', 'netflix', 'show', 'viagem'],
      'Assinaturas': ['assinatura', 'mensal', 'recorrente'],
      'Compras': ['loja', 'market', 'shop', 'compra'],
      'Tecnologia': ['apple', 'google', 'microsoft', 'amazon', 'steam'],
    };

    for (final entry in mapping.entries) {
      if (!categories.any((cat) => _normalizeLine(cat) == _normalizeLine(entry.key))) {
        continue;
      }
      for (final keyword in entry.value) {
        if (normalized.contains(keyword)) {
          return categories.firstWhere(
            (cat) => _normalizeLine(cat) == _normalizeLine(entry.key),
          );
        }
      }
    }

    final fallback = categories.firstWhere(
      (cat) => _normalizeLine(cat) == 'outros',
      orElse: () => categories.isNotEmpty ? categories.first : '',
    );
    return fallback;
  }
}
