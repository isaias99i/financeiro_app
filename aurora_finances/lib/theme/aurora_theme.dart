import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/settings_store.dart';

ThemeData buildAuroraTheme(AppSettingsStore settings) {
  final base = ThemeData.light(useMaterial3: true);
  final seedColor = switch (settings.themeStyle) {
    AppThemeStyle.aurora => const Color(0xFF1EA59A),
    AppThemeStyle.dusk => const Color(0xFF1C5D8F),
    AppThemeStyle.glacier => const Color(0xFF2A8EC7),
  };
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );
  final textScale = settings.textScaleFactor();
  final textTheme = _fontFor(settings.fontFamily, base.textTheme).apply(
    bodyColor: const Color(0xFF0B1B2B),
    displayColor: const Color(0xFF0B1B2B),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _fontFor(settings.fontFamily, base.textTheme).headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFEAF7FF),
            fontSize: 20 * textScale,
          ),
      iconTheme: const IconThemeData(color: Color(0xFFEAF7FF)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

TextTheme _fontFor(AppFontFamily family, TextTheme base) {
  return switch (family) {
    AppFontFamily.spaceGrotesk => GoogleFonts.spaceGroteskTextTheme(base),
    AppFontFamily.manrope => GoogleFonts.manropeTextTheme(base),
    AppFontFamily.outfit => GoogleFonts.outfitTextTheme(base),
  };
}
