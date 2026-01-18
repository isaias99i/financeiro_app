import 'package:flutter/material.dart';

// Badge reutilizavel para indicadores pequenos.
class AuroraBadge extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const AuroraBadge({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.fontSize = 12,
    this.textColor = const Color(0xB3FFFFFF),
    this.backgroundColor = const Color(0x1AFFFFFF),
    this.borderColor = const Color(0x33FFFFFF),
  });

  // Desenha o badge com label e cores customizadas.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
