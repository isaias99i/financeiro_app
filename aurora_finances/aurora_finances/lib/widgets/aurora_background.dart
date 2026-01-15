import 'package:flutter/material.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07111D),
            Color(0xFF0A2B3A),
            Color(0xFF0F3C4F),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: const [
          _GlowBlob(
            color: Color(0xFF1FE6A8),
            size: 320,
            offset: Offset(-120, -80),
            opacity: 0.4,
          ),
          _GlowBlob(
            color: Color(0xFF2AD3FF),
            size: 260,
            offset: Offset(220, 80),
            opacity: 0.35,
          ),
          _GlowBlob(
            color: Color(0xFFB2FF7D),
            size: 300,
            offset: Offset(60, 420),
            opacity: 0.25,
          ),
        ],
      ),
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
