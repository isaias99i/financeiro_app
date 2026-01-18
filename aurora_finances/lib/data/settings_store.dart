import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Estilos de tema disponiveis.
enum AppThemeStyle { aurora, dusk, glacier }
// Nivel de contraste do tema.
enum ContrastLevel { normal, high }
// Escalas de tipografia.
enum TypographyScale { small, normal, large, xlarge }
// Fontes preferidas do app.
enum AppFontFamily { spaceGrotesk, manrope, outfit }
// Formatos de data suportados.
enum DateFormatStyle { dayMonthYear, monthDayYear, yearMonthDay }

// Store de configuracoes persistidas no Firestore.
class AppSettingsStore extends ChangeNotifier {
  // Cria a store com Firestore opcional para testes.
  AppSettingsStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  String? _userId;

  AppThemeStyle themeStyle = AppThemeStyle.aurora;
  ContrastLevel contrastLevel = ContrastLevel.normal;
  TypographyScale typographyScale = TypographyScale.normal;
  AppFontFamily fontFamily = AppFontFamily.spaceGrotesk;
  String currencyLocale = 'pt_BR';
  String currencySymbol = 'R\$';
  DateFormatStyle dateFormatStyle = DateFormatStyle.dayMonthYear;
  final Map<String, String> metricLabels = {};
  final Map<String, int> metricColors = {};

  bool _isLoaded = false;
  // Indica se as configuracoes ja foram carregadas.
  bool get isLoaded => _isLoaded;

  // Carrega configuracoes do usuario logado.
  Future<void> loadForUser(String? userId) async {
    _userId = userId;
    if (userId == null) {
      _resetDefaults();
      _isLoaded = true;
      notifyListeners();
      return;
    }
    final doc = await _docRef().get();
    if (doc.exists) {
      final decoded = doc.data() ?? <String, dynamic>{};
      themeStyle = _themeFromName(decoded['themeStyle'] as String?);
      contrastLevel = _contrastFromName(decoded['contrastLevel'] as String?);
      typographyScale = _scaleFromName(decoded['typographyScale'] as String?);
      fontFamily = _fontFromName(decoded['fontFamily'] as String?);
      currencyLocale = (decoded['currencyLocale'] as String?) ?? currencyLocale;
      currencySymbol = (decoded['currencySymbol'] as String?) ?? currencySymbol;
      dateFormatStyle = _dateFromName(decoded['dateFormatStyle'] as String?);
      final labelsRaw = decoded['metricLabels'] as Map<String, dynamic>?;
      metricLabels.clear();
      if (labelsRaw != null) {
        metricLabels.addAll(
          labelsRaw.map((key, value) => MapEntry(key, value.toString())),
        );
      }
      final colorsRaw = decoded['metricColors'] as Map<String, dynamic>?;
      metricColors.clear();
      if (colorsRaw != null) {
        metricColors.addAll(
          colorsRaw.map((key, value) => MapEntry(key, value as int)),
        );
      }
    } else {
      _resetDefaults();
    }
    _isLoaded = true;
    notifyListeners();
  }

  // Atualiza o tema e persiste.
  void updateTheme(AppThemeStyle style) {
    themeStyle = style;
    _persist();
  }

  // Atualiza o contraste e persiste.
  void updateContrast(ContrastLevel level) {
    contrastLevel = level;
    _persist();
  }

  // Atualiza a escala tipografica e persiste.
  void updateTypographyScale(TypographyScale scale) {
    typographyScale = scale;
    _persist();
  }

  // Atualiza a fonte e persiste.
  void updateFontFamily(AppFontFamily family) {
    fontFamily = family;
    _persist();
  }

  // Atualiza moeda e simbolo.
  void updateCurrency(String locale, String symbol) {
    currencyLocale = locale;
    currencySymbol = symbol;
    _persist();
  }

  // Atualiza o formato de data.
  void updateDateFormat(DateFormatStyle style) {
    dateFormatStyle = style;
    _persist();
  }

  // Atualiza o rotulo de metrica customizada.
  void updateMetricLabel(String metricKey, String label) {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      metricLabels.remove(metricKey);
    } else {
      metricLabels[metricKey] = normalized;
    }
    _persist();
  }

  // Atualiza a cor associada a uma metrica.
  void updateMetricColor(String metricKey, Color color) {
    metricColors[metricKey] = color.toARGB32();
    _persist();
  }

  // Retorna rotulo de metrica com fallback.
  String labelForMetric(String metricKey, String fallback) {
    return metricLabels[metricKey] ?? fallback;
  }

  // Retorna cor de metrica com fallback.
  Color colorForMetric(String metricKey, Color fallback) {
    final stored = metricColors[metricKey];
    if (stored == null) return fallback;
    return Color(stored);
  }

  // Formatter monetario baseado nas preferncias.
  NumberFormat currencyFormatter() {
    return NumberFormat.currency(locale: currencyLocale, symbol: currencySymbol);
  }

  // Formatter de data baseado nas preferncias.
  DateFormat dateFormatter() {
    final pattern = switch (dateFormatStyle) {
      DateFormatStyle.dayMonthYear => 'dd/MM/yyyy',
      DateFormatStyle.monthDayYear => 'MM/dd/yyyy',
      DateFormatStyle.yearMonthDay => 'yyyy-MM-dd',
    };
    return DateFormat(pattern, currencyLocale);
  }

  // Formatter de mes/ano completo.
  DateFormat monthYearFormatter() {
    return DateFormat('MMMM yyyy', currencyLocale);
  }

  // Formatter de mes/ano curto.
  DateFormat shortMonthYearFormatter() {
    return DateFormat('MMM yyyy', currencyLocale);
  }

  // Formatter numerico mes/ano.
  DateFormat numericMonthYearFormatter() {
    return DateFormat('MM/yyyy', currencyLocale);
  }

  // Escala de texto aplicada ao app.
  double textScaleFactor() {
    return switch (typographyScale) {
      TypographyScale.small => 0.92,
      TypographyScale.normal => 1.0,
      TypographyScale.large => 1.08,
      TypographyScale.xlarge => 1.16,
    };
  }

  // Persiste configuracoes no Firestore.
  void _persist() {
    if (!_isLoaded || _userId == null) return;
    final payload = jsonEncode({
      'themeStyle': themeStyle.name,
      'contrastLevel': contrastLevel.name,
      'typographyScale': typographyScale.name,
      'fontFamily': fontFamily.name,
      'currencyLocale': currencyLocale,
      'currencySymbol': currencySymbol,
      'dateFormatStyle': dateFormatStyle.name,
      'metricLabels': metricLabels,
      'metricColors': metricColors,
    });
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    _docRef().set(decoded);
    notifyListeners();
  }

  // Converte string para enum de tema.
  AppThemeStyle _themeFromName(String? name) {
    return AppThemeStyle.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AppThemeStyle.aurora,
    );
  }

  // Converte string para enum de contraste.
  ContrastLevel _contrastFromName(String? name) {
    return ContrastLevel.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ContrastLevel.normal,
    );
  }

  // Converte string para enum de tipografia.
  TypographyScale _scaleFromName(String? name) {
    return TypographyScale.values.firstWhere(
      (value) => value.name == name,
      orElse: () => TypographyScale.normal,
    );
  }

  // Converte string para enum de fonte.
  AppFontFamily _fontFromName(String? name) {
    return AppFontFamily.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AppFontFamily.spaceGrotesk,
    );
  }

  // Converte string para enum de formato de data.
  DateFormatStyle _dateFromName(String? name) {
    return DateFormatStyle.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DateFormatStyle.dayMonthYear,
    );
  }

  // Referencia ao documento de configuracoes do usuario.
  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('data');
  }

  // Restaura valores padrao.
  void _resetDefaults() {
    themeStyle = AppThemeStyle.aurora;
    contrastLevel = ContrastLevel.normal;
    typographyScale = TypographyScale.normal;
    fontFamily = AppFontFamily.spaceGrotesk;
    currencyLocale = 'pt_BR';
    currencySymbol = 'R\$';
    dateFormatStyle = DateFormatStyle.dayMonthYear;
    metricLabels.clear();
    metricColors.clear();
  }
}
