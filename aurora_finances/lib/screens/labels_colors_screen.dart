import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../models/menu_models.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';

// Tela de rotulos e cores dos indicadores.
class LabelsColorsScreen extends StatelessWidget {
  const LabelsColorsScreen({super.key});

  @override
  // Monta o editor de rotulos e cores.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Rotulos e cores'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Indicadores',
            subtitle: 'Nomes e cores do resumo financeiro',
            child: Column(
              children: MenuMetric.values.map((metric) {
                return _MetricEditor(
                  metric: metric,
                  settings: settings,
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

  const _MetricEditor({
    required this.metric,
    required this.settings,
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
    final fallbackColor = _defaultMetricColor(widget.metric);
    final selectedColor = widget.settings.colorForMetric(key, fallbackColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            menuMetricTitle(widget.metric),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: (value) => widget.settings.updateMetricLabel(key, value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Rotulo',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7FD7FF), width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((color) {
              final isSelected = color.toARGB32() == selectedColor.toARGB32();
              return InkWell(
                onTap: () => widget.settings.updateMetricColor(key, color),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
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
  Color _defaultMetricColor(MenuMetric metric) {
    return switch (metric) {
      MenuMetric.receitas => const Color(0xFF1FAF86),
      MenuMetric.despesas => const Color(0xFF2A2D3C),
      MenuMetric.saldoMensal => const Color(0xFF1C8EC9),
      MenuMetric.saldoAposReserva => const Color(0xFF1D9C7C),
      MenuMetric.saldoAtual => const Color(0xFF1C7C9C),
      MenuMetric.segurancaAno => const Color(0xFF3D5BA9),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

const List<Color> _colorOptions = [
  Color(0xFF1C8EC9),
  Color(0xFF1FAF86),
  Color(0xFFE19932),
  Color(0xFFE36A4F),
  Color(0xFF3D5BA9),
  Color(0xFF254A6A),
  Color(0xFF8E44AD),
  Color(0xFF2ECC71),
];
