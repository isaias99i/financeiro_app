import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';
import '../theme/app_layout.dart';
import '../theme/app_tokens.dart';

// Tela de configuracao de tipografia.
class TypographyScreen extends StatelessWidget {
  const TypographyScreen({super.key});

  @override
  // Monta as opcoes de fonte e escala.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Tipografia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.spaceLg),
        children: [
          _SectionCard(
            title: 'Fonte',
            subtitle: 'Escolha a familia tipografica',
            child: DropdownButtonFormField<AppFontFamily>(
              initialValue: settings.fontFamily,
              decoration: _inputDecoration(tokens),
              dropdownColor: tokens.surface,
              items: AppFontFamily.values
                  .map(
                    (font) => DropdownMenuItem(
                      value: font,
                      child: Text(_fontLabel(font)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                settings.updateFontFamily(value);
              },
            ),
          ),
          const SizedBox(height: AppLayout.spaceMd),
          _SectionCard(
            title: 'Tamanho',
            subtitle: 'Ajuste o tamanho do texto',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: settings.textScaleFactor(),
                  min: 0.92,
                  max: 1.16,
                  divisions: 3,
                  label: _scaleLabel(settings.typographyScale),
                  onChanged: (value) {
                    settings.updateTypographyScale(_scaleFromValue(value));
                  },
                ),
                Text(
                  'Exemplo: O seu saldo atual esta sempre visivel.',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Retorna label amigavel da fonte.
  String _fontLabel(AppFontFamily font) {
    return switch (font) {
      AppFontFamily.spaceGrotesk => 'Space Grotesk',
      AppFontFamily.manrope => 'Manrope',
      AppFontFamily.outfit => 'Outfit',
    };
  }

  // Retorna label da escala tipografica.
  String _scaleLabel(TypographyScale scale) {
    return switch (scale) {
      TypographyScale.small => 'Pequeno',
      TypographyScale.normal => 'Normal',
      TypographyScale.large => 'Grande',
      TypographyScale.xlarge => 'Extra grande',
    };
  }

  // Converte valor do slider em escala.
  TypographyScale _scaleFromValue(double value) {
    if (value <= 0.92) return TypographyScale.small;
    if (value <= 1.0) return TypographyScale.normal;
    if (value <= 1.08) return TypographyScale.large;
    return TypographyScale.xlarge;
  }

  // Cria decoracao padrao dos campos.
  InputDecoration _inputDecoration(AppThemeTokens tokens) {
    return InputDecoration(
      filled: true,
      fillColor: tokens.surfaceAlt,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
        borderSide: BorderSide(color: tokens.focus, width: 1.2),
      ),
    );
  }
}

// Card de secao reutilizavel.
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  // Monta o card de secao.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceLgTight),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.spaceXs),
          Text(
            subtitle,
            style: TextStyle(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppLayout.spaceMd),
          child,
        ],
      ),
    );
  }
}
