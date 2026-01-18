import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

// Badge reutilizavel para indicadores pequenos.
class AuroraBadge extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const AuroraBadge({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.fontSize = 12,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  // Desenha o badge com label e cores customizadas.
  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? tokens.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? tokens.textSecondary,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
