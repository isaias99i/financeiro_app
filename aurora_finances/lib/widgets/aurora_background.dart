import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import 'app_settings_scope.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final palette = _paletteFor(settings);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.background,
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _GlowBlob(
            color: palette.glowA,
            size: 320,
            offset: const Offset(-120, -80),
            opacity: palette.glowOpacity,
          ),
          _GlowBlob(
            color: palette.glowB,
            size: 260,
            offset: const Offset(220, 80),
            opacity: palette.glowOpacity - 0.05,
          ),
          _GlowBlob(
            color: palette.glowC,
            size: 300,
            offset: const Offset(60, 420),
            opacity: palette.glowOpacity - 0.15,
          ),
        ],
      ),
    );
  }
}

class _AuroraPalette {
  final List<Color> background;
  final Color glowA;
  final Color glowB;
  final Color glowC;
  final double glowOpacity;

  const _AuroraPalette({
    required this.background,
    required this.glowA,
    required this.glowB,
    required this.glowC,
    required this.glowOpacity,
  });
}

_AuroraPalette _paletteFor(AppSettingsStore settings) {
  final contrastBoost = settings.contrastLevel == ContrastLevel.high ? 0.08 : 0.0;
  switch (settings.themeStyle) {
    case AppThemeStyle.aurora:
      return _AuroraPalette(
        background: const [
          Color(0xFF07111D),
          Color(0xFF0A2B3A),
          Color(0xFF0F3C4F),
        ],
        glowA: const Color(0xFF1FE6A8),
        glowB: const Color(0xFF2AD3FF),
        glowC: const Color(0xFFB2FF7D),
        glowOpacity: 0.4 + contrastBoost,
      );
    case AppThemeStyle.dusk:
      return _AuroraPalette(
        background: const [
          Color(0xFF0C0F1B),
          Color(0xFF1B1C33),
          Color(0xFF23284A),
        ],
        glowA: const Color(0xFF8E7BFF),
        glowB: const Color(0xFF4BC3FF),
        glowC: const Color(0xFFFFA657),
        glowOpacity: 0.35 + contrastBoost,
      );
    case AppThemeStyle.glacier:
      return _AuroraPalette(
        background: const [
          Color(0xFF06141A),
          Color(0xFF0B2C36),
          Color(0xFF123E4B),
        ],
        glowA: const Color(0xFF7DE6FF),
        glowB: const Color(0xFF4FF3C7),
        glowC: const Color(0xFF9BC3FF),
        glowOpacity: 0.38 + contrastBoost,
      );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset offset;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.offset,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
