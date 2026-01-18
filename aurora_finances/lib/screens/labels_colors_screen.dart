import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../models/menu_models.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';
import '../theme/app_layout.dart';
import '../theme/app_tokens.dart';

// Tela de rotulos e cores dos indicadores.
class LabelsColorsScreen extends StatelessWidget {
  const LabelsColorsScreen({super.key});

  @override
  // Monta o editor de rotulos e cores.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Rotulos e cores'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.spaceLg),
        children: [
          _SectionCard(
            title: 'Indicadores',
            subtitle: 'Nomes e cores do resumo financeiro',
            child: Column(
              children: MenuMetric.values.map((metric) {
                return _MetricEditor(
                  metric: metric,
                  settings: settings,
                  tokens: tokens,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Editor de rotulo e cor por indicador.
class _MetricEditor extends StatefulWidget {
  final MenuMetric metric;
  final AppSettingsStore settings;
  final AppThemeTokens tokens;

  const _MetricEditor({
    required this.metric,
    required this.settings,
    required this.tokens,
  });

  @override
  // Cria o estado do editor do indicador.
  State<_MetricEditor> createState() => _MetricEditorState();
}

// Estado do editor de indicador.
class _MetricEditorState extends State<_MetricEditor> {
  late final TextEditingController _controller;

  @override
  // Inicializa o controller do rotulo.
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.settings.labelForMetric(
        menuMetricKey(widget.metric),
        menuMetricTitle(widget.metric),
      ),
    );
  }

  @override
  // Atualiza o texto quando muda o indicador.
  void didUpdateWidget(covariant _MetricEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric != widget.metric) {
      _controller.text = widget.settings.labelForMetric(
        menuMetricKey(widget.metric),
        menuMetricTitle(widget.metric),
      );
    }
  }

  @override
  // Libera o controller do rotulo.
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  // Monta o card de edicao do indicador.
  Widget build(BuildContext context) {
    final key = menuMetricKey(widget.metric);
    final fallbackColor = _defaultMetricColor(widget.metric, widget.tokens);
    final selectedColor = widget.settings.colorForMetric(key, fallbackColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppLayout.spaceMd),
      decoration: BoxDecoration(
        color: widget.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppLayout.radiusLgTight),
        border: Border.all(color: widget.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            menuMetricTitle(widget.metric),
            style: TextStyle(
              color: widget.tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppLayout.spaceSm),
          TextField(
            controller: _controller,
            onChanged: (value) => widget.settings.updateMetricLabel(key, value),
            style: TextStyle(color: widget.tokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Rotulo',
              filled: true,
              fillColor: widget.tokens.surfaceAlt,
              labelStyle: TextStyle(color: widget.tokens.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusMd),
                borderSide: BorderSide(color: widget.tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusMd),
                borderSide: BorderSide(color: widget.tokens.focus, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Wrap(
            spacing: AppLayout.spaceSm,
            runSpacing: AppLayout.spaceSm,
            children: widget.tokens.metricPaletteColors.map((color) {
              final isSelected = color.toARGB32() == selectedColor.toARGB32();
              return InkWell(
                onTap: () => widget.settings.updateMetricColor(key, color),
                borderRadius: BorderRadius.circular(AppLayout.radiusXl),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? widget.tokens.textPrimary
                          : widget.tokens.background.withValues(alpha: 0.0),
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Define a cor padrao para cada indicador.
  Color _defaultMetricColor(MenuMetric metric, AppThemeTokens tokens) {
    return switch (metric) {
      MenuMetric.receitas => tokens.metricColor(MetricColorRole.receitas),
      MenuMetric.despesas => tokens.metricColor(MetricColorRole.despesas),
      MenuMetric.saldoMensal => tokens.metricColor(MetricColorRole.saldoMensalPositivo),
      MenuMetric.saldoAposReserva =>
        tokens.metricColor(MetricColorRole.saldoAposReservaPositivo),
      MenuMetric.saldoAtual => tokens.metricColor(MetricColorRole.saldoAtual),
      MenuMetric.segurancaAno => tokens.metricColor(MetricColorRole.segurancaAno),
    };
  }
}

// Card de secao para agrupar edicoes.
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
