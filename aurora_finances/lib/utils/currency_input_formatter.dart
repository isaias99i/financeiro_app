import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Formata entrada de moeda enquanto o usuario digita.
class CurrencyInputFormatter extends TextInputFormatter {
  // Configura locale e simbolo usados na formatacao.
  CurrencyInputFormatter({required this.locale, required this.symbol})
    : _formatter = NumberFormat.currency(locale: locale, symbol: symbol);

  final String locale;
  final String symbol;
  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Mantem apenas digitos e aplica formatacao monetaria.
    final buffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      if (rune >= 48 && rune <= 57) {
        buffer.writeCharCode(rune);
      }
    }
    final digits = buffer.toString();
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) {
      return oldValue;
    }
    final value = parsed / 100.0;
    final text = _formatter.format(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Converte um texto de moeda para double.
double parseCurrencyToDouble(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.isEmpty) {
    return 0.0;
  }
  final parsed = int.tryParse(cleaned);
  if (parsed == null) {
    return 0.0;
  }
  return parsed / 100.0;
}
