import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { aurora, dusk, glacier }
enum ContrastLevel { normal, high }
enum TypographyScale { small, normal, large, xlarge }
enum AppFontFamily { spaceGrotesk, manrope, outfit }
enum DateFormatStyle { dayMonthYear, monthDayYear, yearMonthDay }

class AppSettingsStore extends ChangeNotifier {
  static const _settingsKey = 'app_settings';

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
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      themeStyle = _themeFromName(decoded['themeStyle'] as String?);
      contrastLevel = _contrastFromName(decoded['contrastLevel'] as String?);
      typographyScale = _scaleFromName(decoded['typographyScale'] as String?);
      fontFamily = _fontFromName(decoded['fontFamily'] as String?);
      currencyLocale = (decoded['currencyLocale'] as String?) ?? currencyLocale;
      currencySymbol = (decoded['currencySymbol'] as String?) ?? currencySymbol;
      dateFormatStyle = _dateFromName(decoded['dateFormatStyle'] as String?);
      final labelsRaw = decoded['metricLabels'] as Map<String, dynamic>?;
      if (labelsRaw != null) {
        metricLabels
          ..clear()
          ..addAll(labelsRaw.map((key, value) => MapEntry(key, value.toString())));
      }
      final colorsRaw = decoded['metricColors'] as Map<String, dynamic>?;
      if (colorsRaw != null) {
        metricColors
          ..clear()
          ..addAll(colorsRaw.map((key, value) => MapEntry(key, value as int)));
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  void updateTheme(AppThemeStyle style) {
    themeStyle = style;
    _persist();
  }

  void updateContrast(ContrastLevel level) {
    contrastLevel = level;
    _persist();
  }

  void updateTypographyScale(TypographyScale scale) {
    typographyScale = scale;
    _persist();
  }

  void updateFontFamily(AppFontFamily family) {
    fontFamily = family;
    _persist();
  }

  void updateCurrency(String locale, String symbol) {
    currencyLocale = locale;
    currencySymbol = symbol;
    _persist();
  }

  void updateDateFormat(DateFormatStyle style) {
    dateFormatStyle = style;
    _persist();
  }

  void updateMetricLabel(String metricKey, String label) {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      metricLabels.remove(metricKey);
    } else {
      metricLabels[metricKey] = normalized;
    }
    _persist();
  }

  void updateMetricColor(String metricKey, Color color) {
    metricColors[metricKey] = color.toARGB32();
    _persist();
  }

  String labelForMetric(String metricKey, String fallback) {
    return metricLabels[metricKey] ?? fallback;
  }

  Color colorForMetric(String metricKey, Color fallback) {
    final stored = metricColors[metricKey];
    if (stored == null) return fallback;
    return Color(stored);
  }

  NumberFormat currencyFormatter() {
    return NumberFormat.currency(locale: currencyLocale, symbol: currencySymbol);
  }

  DateFormat dateFormatter() {
    final pattern = switch (dateFormatStyle) {
      DateFormatStyle.dayMonthYear => 'dd/MM/yyyy',
      DateFormatStyle.monthDayYear => 'MM/dd/yyyy',
      DateFormatStyle.yearMonthDay => 'yyyy-MM-dd',
    };
    return DateFormat(pattern, currencyLocale);
  }

  DateFormat monthYearFormatter() {
    return DateFormat('MMMM yyyy', currencyLocale);
  }

  DateFormat shortMonthYearFormatter() {
    return DateFormat('MMM yyyy', currencyLocale);
  }

  DateFormat numericMonthYearFormatter() {
    return DateFormat('MM/yyyy', currencyLocale);
  }

  double textScaleFactor() {
    return switch (typographyScale) {
      TypographyScale.small => 0.92,
      TypographyScale.normal => 1.0,
      TypographyScale.large => 1.08,
      TypographyScale.xlarge => 1.16,
    };
  }

  void _persist() {
    if (!_isLoaded) return;
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
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_settingsKey, payload);
    });
    notifyListeners();
  }

  AppThemeStyle _themeFromName(String? name) {
    return AppThemeStyle.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AppThemeStyle.aurora,
    );
  }

  ContrastLevel _contrastFromName(String? name) {
    return ContrastLevel.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ContrastLevel.normal,
    );
  }

  TypographyScale _scaleFromName(String? name) {
    return TypographyScale.values.firstWhere(
      (value) => value.name == name,
      orElse: () => TypographyScale.normal,
    );
  }

  AppFontFamily _fontFromName(String? name) {
    return AppFontFamily.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AppFontFamily.spaceGrotesk,
    );
  }

  DateFormatStyle _dateFromName(String? name) {
    return DateFormatStyle.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DateFormatStyle.dayMonthYear,
    );
  }
}
