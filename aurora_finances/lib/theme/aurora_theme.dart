import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/settings_store.dart';
import 'app_themes.dart';

// Monta o tema principal com base no preset selecionado.
ThemeData buildAuroraTheme(AppSettingsStore settings) {
  final preset = themePresetById(settings.themePresetId);
  final base = ThemeData(
    useMaterial3: true,
    brightness: preset.brightness,
  );
  final tokens = preset.tokens;
  final textScale = settings.textScaleFactor();
  final textTheme = _fontFor(settings.fontFamily, base.textTheme).apply(
    bodyColor: tokens.textPrimary,
    displayColor: tokens.textPrimary,
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.primary,
    brightness: preset.brightness,
  ).copyWith(
    primary: tokens.primary,
    onPrimary: tokens.textPrimary,
    secondary: tokens.secondary,
    onSecondary: tokens.textPrimary,
    tertiary: tokens.accent,
    onTertiary: tokens.textPrimary,
    error: tokens.danger,
    onError: tokens.textPrimary,
    surface: tokens.surface,
    onSurface: tokens.textPrimary,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: tokens.border),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.background,
    textTheme: textTheme,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.background.withValues(alpha: 0.0),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
        fontSize: 20 * textScale,
      ),
      iconTheme: IconThemeData(color: tokens.textPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: tokens.border,
    iconTheme: IconThemeData(color: tokens.textSecondary),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.surfaceStrong,
      contentTextStyle: TextStyle(color: tokens.textPrimary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: tokens.textPrimary),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceAlt,
      labelStyle: TextStyle(color: tokens.textSecondary),
      hintStyle: TextStyle(color: tokens.textMuted),
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: tokens.focus, width: 1.4),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: tokens.accent,
      inactiveTrackColor: tokens.border,
      thumbColor: tokens.accent,
    ),
  );
}

// Seleciona a fonte conforme a preferencia.
TextTheme _fontFor(AppFontFamily family, TextTheme base) {
  return switch (family) {
    AppFontFamily.spaceGrotesk => GoogleFonts.spaceGroteskTextTheme(base),
    AppFontFamily.manrope => GoogleFonts.manropeTextTheme(base),
    AppFontFamily.outfit => GoogleFonts.outfitTextTheme(base),
  };
}
