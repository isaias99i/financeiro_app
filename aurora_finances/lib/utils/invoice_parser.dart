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
  static final RegExp _amountRegex =
      RegExp(r'([+\-]?)\s*R?\$?\s*(-?\d{1,3}(?:\.\d{3})*,\d{2})');
  static final RegExp _installmentSlash = RegExp(r'\b(\d{1,2})\s*\/\s*(\d{1,2})\b');
  static final RegExp _installmentWord = RegExp(r'\b(\d{1,2})\s+de\s+(\d{1,2})\b');

  static const Map<String, int> _ptMonths = {
    'jan': 1,
    'janeiro': 1,
    'fev': 2,
    'fevereiro': 2,
    'mar': 3,
    'marco': 3,
    'março': 3,
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

  static List<InvoiceParsedItem> parse(String text, {required DateTime referenceDate}) {
    // Faz parsing linha a linha com suporte a multiline (descricao + valor).
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final results = <InvoiceParsedItem>[];
    DateTime? currentDate;
    String? currentDescription;
    InvoiceInstallmentInfo? currentInstallment;
    String? pendingDescription;

    // Some PDFs split "date/description" and "amount" across different lines.
    for (final line in lines) {
      if (_shouldSkip(line)) {
        continue;
      }
      final date = _parseDate(line, referenceDate);
      if (date != null) {
        currentDate = date;
        currentInstallment = _parseInstallment(line);
        final inline = _extractDescription(line, date, currentInstallment);
        currentDescription = inline.isNotEmpty ? inline : pendingDescription;
        pendingDescription = null;
      }

      final amount = _parseAmount(line);
      if (currentDate != null && amount != null) {
        var description = currentDescription ?? '';
        if (description.isEmpty) {
          description = pendingDescription ?? _stripAmount(line);
        }
        if (description.isEmpty) {
          description = 'Lancamento';
        }
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
        pendingDescription = null;
        continue;
      }

      if (date == null && amount == null) {
        if (currentDate != null && (currentDescription == null || currentDescription.isEmpty)) {
          pendingDescription ??= line;
        }
      }
    }
    return results;
  }

  static DateTime? _parseDate(String line, DateTime referenceDate) {
    // Tenta data numerica e data PT-BR (ex.: 12 de nov. 2025).
    return _parseNumericDate(line, referenceDate) ?? _parsePtDate(line);
  }

  static DateTime? _parseNumericDate(String line, DateTime referenceDate) {
    // Datas no formato 12/11/2025 ou 12-11-25.
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

  static DateTime? _parsePtDate(String line) {
    // Datas PT-BR com mes abreviado ou por extenso.
    final match = _datePt.firstMatch(line);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final monthToken = (match.group(2) ?? '').toLowerCase().replaceAll('.', '');
    final month = _ptMonths[monthToken];
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static double? _parseAmount(String line) {
    // Extrai valor monetario, respeitando sinais + e -.
    final matches = _amountRegex.allMatches(line).toList();
    if (matches.isEmpty) return null;
    final match = matches.last;
    final sign = match.group(1) ?? '';
    final raw = match.group(2) ?? '';
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    if (sign.contains('-')) return -value;
    return value;
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
      return columns[1].trim();
    }
    return _stripAmount(line);
  }

  static String _stripAmount(String line) {
    // Remove data e valor para restar somente a descricao.
    var cleaned = line;
    cleaned = cleaned.replaceFirst(_dateNumeric, '');
    cleaned = cleaned.replaceFirst(_datePt, '');
    cleaned = cleaned.replaceFirst(_amountRegex, '');
    cleaned = cleaned.replaceAll(RegExp(r'[-+]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+[-+]\s*'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _shouldSkip(String line) {
    // Ignora cabecalhos e linhas que nao sao lancamentos.
    final normalized = line.toLowerCase();
    if (normalized.startsWith('data movimentacao')) return true;
    if (normalized.startsWith('total ')) return true;
    if (normalized.contains('total cartao')) return true;
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
    final normalized = description.toLowerCase();
    for (final category in categories) {
      if (category.trim().isEmpty) continue;
      final name = category.toLowerCase();
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
      if (!categories.any((cat) => cat.toLowerCase() == entry.key.toLowerCase())) {
        continue;
      }
      for (final keyword in entry.value) {
        if (normalized.contains(keyword)) {
          return categories.firstWhere(
            (cat) => cat.toLowerCase() == entry.key.toLowerCase(),
          );
        }
      }
    }

    final fallback = categories.firstWhere(
      (cat) => cat.toLowerCase() == 'outros',
      orElse: () => categories.isNotEmpty ? categories.first : '',
    );
    return fallback;
  }
}
