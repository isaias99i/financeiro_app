import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AppThemeStyle { aurora, dusk, glacier }
enum ContrastLevel { normal, high }
enum TypographyScale { small, normal, large, xlarge }
enum AppFontFamily { spaceGrotesk, manrope, outfit }
enum DateFormatStyle { dayMonthYear, monthDayYear, yearMonthDay }

class AppSettingsStore extends ChangeNotifier {
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
  bool get isLoaded => _isLoaded;

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

  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('data');
  }

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
