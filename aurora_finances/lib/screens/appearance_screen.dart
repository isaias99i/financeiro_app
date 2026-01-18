import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';

// Tela de escolha de tema e contraste.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  // Monta opcoes de tema e contraste.
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Aparencia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Tema',
            subtitle: 'Escolha o estilo do fundo',
            child: RadioGroup<AppThemeStyle>(
              groupValue: settings.themeStyle,
              onChanged: (value) {
                if (value == null) return;
                settings.updateTheme(value);
              },
              child: Column(
                children: AppThemeStyle.values.map((style) {
                  return RadioListTile<AppThemeStyle>(
                    value: style,
                    title: Text(_themeLabel(style), style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Contraste',
            subtitle: 'Realce elementos de interface',
            child: RadioGroup<ContrastLevel>(
              groupValue: settings.contrastLevel,
              onChanged: (value) {
                if (value == null) return;
                settings.updateContrast(value);
              },
              child: Column(
                children: ContrastLevel.values.map((level) {
                  return RadioListTile<ContrastLevel>(
                    value: level,
                    title: Text(_contrastLabel(level), style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Rotulo do tema para exibicao.
  String _themeLabel(AppThemeStyle style) {
    return switch (style) {
      AppThemeStyle.aurora => 'Aurora',
      AppThemeStyle.dusk => 'Dusk',
      AppThemeStyle.glacier => 'Glacier',
    };
  }

  // Rotulo do contraste para exibicao.
  String _contrastLabel(ContrastLevel level) {
    return switch (level) {
      ContrastLevel.normal => 'Normal',
      ContrastLevel.high => 'Alto contraste',
    };
  }
}

// Card generico de secao.
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  // Layout padrao da secao.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
