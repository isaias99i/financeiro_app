import 'package:flutter/material.dart';

import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';
import '../theme/app_themes.dart';
import '../theme/app_layout.dart';
import '../theme/app_tokens.dart';

// Tela de escolha de tema dinamico.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  // Monta opcoes de tema dinamico.
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    final textStyle = TextStyle(color: tokens.textPrimary);

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Aparencia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.spaceLg),
        children: [
          _SectionCard(
            title: 'Tema',
            subtitle: 'Escolha um tema Aurora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemeGroup(
                  title: 'Claros',
                  presets: lightThemePresets,
                  selectedId: settings.themePresetId,
                  onSelected: settings.updateThemePreset,
                  textStyle: textStyle,
                ),
                const SizedBox(height: AppLayout.spaceMd),
                _ThemeGroup(
                  title: 'Escuros',
                  presets: darkThemePresets,
                  selectedId: settings.themePresetId,
                  onSelected: settings.updateThemePreset,
                  textStyle: textStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Grupo de temas por modo (claro/escuro).
class _ThemeGroup extends StatelessWidget {
  final String title;
  final List<AppThemePreset> presets;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final TextStyle textStyle;

  const _ThemeGroup({
    required this.title,
    required this.presets,
    required this.selectedId,
    required this.onSelected,
    required this.textStyle,
  });

  @override
  // Monta a lista de temas do grupo.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textStyle.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppLayout.spaceSm),
        RadioGroup<String>(
          groupValue: selectedId,
          onChanged: (value) {
            if (value == null) return;
            onSelected(value);
          },
          child: Column(
            children: presets.map((preset) {
              return RadioListTile<String>(
                value: preset.id,
                title: Text(preset.name, style: textStyle),
                activeColor: tokens.accent,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
      ],
    );
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
  // Monta o container de secao.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: AppLayout.spaceSm),
          child,
        ],
      ),
    );
  }
}
