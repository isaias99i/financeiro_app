import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Papéis semanticos para cores do resumo financeiro.
enum MetricColorRole {
  receitas,
  despesas,
  saldoMensalPositivo,
  saldoMensalNegativo,
  saldoAposReservaPositivo,
  saldoAposReservaNegativo,
  saldoAtual,
  segurancaAno,
  fallback,
}

// Tokens semanticos do tema para evitar cores hardcoded na UI.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceStrong;
  final Color border;
  final Color borderStrong;
  final Color focus;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color shadow;
  final List<Color> heroGradient;
  final List<Color> panelGradient;
  final List<Color> backgroundGradient;
  final List<Color> glowColors;
  final double glowOpacity;
  final Map<MetricColorRole, Color> metricColors;
  final List<MetricColorRole> metricPaletteOrder;

  const AppThemeTokens({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceStrong,
    required this.border,
    required this.borderStrong,
    required this.focus,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.shadow,
    required this.heroGradient,
    required this.panelGradient,
    required this.backgroundGradient,
    required this.glowColors,
    required this.glowOpacity,
    required this.metricColors,
    required this.metricPaletteOrder,
  });

  // Resolve a cor semantica de indicador.
  Color metricColor(MetricColorRole role) {
    return metricColors[role] ?? metricColors[MetricColorRole.fallback]!;
  }

  // Lista de cores para seletores de paleta.
  List<Color> get metricPaletteColors {
    return metricPaletteOrder.map(metricColor).toList(growable: false);
  }

  Color get metricFallback => metricColor(MetricColorRole.fallback);

  // Acesso rapido aos tokens do tema.
  static AppThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    assert(tokens != null, 'AppThemeTokens not found in ThemeData.');
    return tokens!;
  }

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceStrong,
    Color? border,
    Color? borderStrong,
    Color? focus,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? shadow,
    List<Color>? heroGradient,
    List<Color>? panelGradient,
    List<Color>? backgroundGradient,
    List<Color>? glowColors,
    double? glowOpacity,
    Map<MetricColorRole, Color>? metricColors,
    List<MetricColorRole>? metricPaletteOrder,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      focus: focus ?? this.focus,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      shadow: shadow ?? this.shadow,
      heroGradient: heroGradient ?? this.heroGradient,
      panelGradient: panelGradient ?? this.panelGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glowColors: glowColors ?? this.glowColors,
      glowOpacity: glowOpacity ?? this.glowOpacity,
      metricColors: metricColors ?? this.metricColors,
      metricPaletteOrder: metricPaletteOrder ?? this.metricPaletteOrder,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t)!,
      backgroundAlt: Color.lerp(backgroundAlt, other.backgroundAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      heroGradient: _lerpColors(heroGradient, other.heroGradient, t),
      panelGradient: _lerpColors(panelGradient, other.panelGradient, t),
      backgroundGradient: _lerpColors(backgroundGradient, other.backgroundGradient, t),
      glowColors: _lerpColors(glowColors, other.glowColors, t),
      glowOpacity: ui.lerpDouble(glowOpacity, other.glowOpacity, t) ?? glowOpacity,
      metricColors: _lerpMetricColors(metricColors, other.metricColors, t),
      metricPaletteOrder: metricPaletteOrder,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) {
    final count = a.length < b.length ? a.length : b.length;
    return List<Color>.generate(
      count,
      (index) => Color.lerp(a[index], b[index], t) ?? a[index],
    );
  }

  static Map<MetricColorRole, Color> _lerpMetricColors(
    Map<MetricColorRole, Color> a,
    Map<MetricColorRole, Color> b,
    double t,
  ) {
    final roles = <MetricColorRole>{...a.keys, ...b.keys};
    final result = <MetricColorRole, Color>{};
    for (final role in roles) {
      final colorA = a[role];
      final colorB = b[role];
      if (colorA == null) {
        result[role] = colorB!;
      } else if (colorB == null) {
        result[role] = colorA;
      } else {
        result[role] = Color.lerp(colorA, colorB, t) ?? colorA;
      }
    }
    return result;
  }
}
