import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAuroraTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1EA59A),
    brightness: Brightness.light,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFF0B1B2B),
      displayColor: const Color(0xFF0B1B2B),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFEAF7FF),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFEAF7FF)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
