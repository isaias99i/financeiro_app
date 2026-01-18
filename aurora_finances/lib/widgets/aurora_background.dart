import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

// Fundo com gradiente e blobs de luz.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  // Desenha fundo de acordo com o tema atual.
  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.backgroundGradient,
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _GlowBlob(
            color: tokens.glowColors[0],
            size: 320,
            offset: const Offset(-120, -80),
            opacity: tokens.glowOpacity,
          ),
          _GlowBlob(
            color: tokens.glowColors[1],
            size: 260,
            offset: const Offset(220, 80),
            opacity: tokens.glowOpacity - 0.05,
          ),
          _GlowBlob(
            color: tokens.glowColors[2],
            size: 300,
            offset: const Offset(60, 420),
            opacity: tokens.glowOpacity - 0.15,
          ),
        ],
      ),
    );
  }
}

// Elemento circular com gradiente para brilho.
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

  // Posiciona o blob no fundo.
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
