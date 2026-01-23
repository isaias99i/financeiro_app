import 'package:flutter/material.dart';
import '../data/menu_store.dart';
import '../data/despesas_store.dart';
import '../data/receitas_store.dart';
import '../data/categories_store.dart';
import '../data/settings_store.dart';
import '../models/menu_models.dart';
import '../screens/despesas_screen.dart';
import '../screens/receitas_screen.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_tokens.dart';
import '../theme/app_layout.dart';

// Widget do resumo financeiro com indicadores reordenaveis.
class ResumoFinanceiroWidget extends StatefulWidget {
  final MenuStore menuStore;
  final ReceitasStore receitasStore;
  final ExpensesStore expensesStore;
  final CategoriesStore entryCategoriesStore;
  final double receitas;
  final double despesas;
  final double saldoMensal;
  final double saldoAposReserva;
  final double saldoAtual;
  final double segurancaAno;

  const ResumoFinanceiroWidget({
    required this.menuStore,
    required this.receitasStore,
    required this.expensesStore,
    required this.entryCategoriesStore,
    required this.receitas,
    required this.despesas,
    required this.saldoMensal,
    required this.saldoAposReserva,
    required this.saldoAtual,
    required this.segurancaAno,
    super.key,
  });

  @override
  // Cria o estado do resumo financeiro.
  State<ResumoFinanceiroWidget> createState() => _ResumoFinanceiroWidgetState();
}

// Estado do resumo financeiro com painel expansivel.
class _ResumoFinanceiroWidgetState extends State<ResumoFinanceiroWidget> {
  bool _isExpanded = true;

  @override
  // Monta a UI com indicadores e painel expansivel.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    return AnimatedBuilder(
      animation: widget.menuStore,
      builder: (context, _) {
        return ExpansionPanelList(
          elevation: 0,
          dividerColor: tokens.border,
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          children: [
            ExpansionPanel(
              backgroundColor: tokens.surfaceAlt,
              isExpanded: _isExpanded,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.spaceLg,
                    vertical: AppLayout.spaceXs,
                  ),
                  title: Text(
                    'Resumo Financeiro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.spaceLg,
                  AppLayout.spaceSm,
                  AppLayout.spaceLg,
                  AppLayout.spaceLg,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppLayout.radiusLg),
                    border: Border.all(color: tokens.border),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.spaceMd,
                    AppLayout.spaceMd,
                    AppLayout.spaceMd,
                    AppLayout.spaceMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Indicadores',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Arraste para ordenar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppLayout.spaceSm),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: widget.menuStore.orderedItems.length + 1,
                        onReorder: widget.menuStore.reorderOrderedItems,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: tokens.background.withValues(alpha: 0.0),
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        itemBuilder: (context, index) {
                          if (index < widget.menuStore.orderedItems.length) {
                            final entry = widget.menuStore.orderedItems[index];
                            return KeyedSubtree(
                              key: ValueKey(entry.item.id),
                              child: ReorderableDelayedDragStartListener(
                                index: index,
                                child: _MenuItemRow(
                                  title: _resolveTitle(settings, entry.item),
                                  value: _resolveValue(entry.item),
                                  color: _resolveColor(entry.item),
                                  onTap: _resolveTap(entry.item),
                                  onRemove: () => widget.menuStore.removeItem(
                                    entry.type,
                                    entry.item.id,
                                  ),
                                  dragHandle: ReorderableDragStartListener(
                                    index: index,
                                    child: Tooltip(
                                      message: 'Arrastar para reordenar',
                                      child: Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          color: tokens.surfaceAlt,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.drag_indicator,
                                          size: 16,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return _AddCard(
                            key: const ValueKey('add-card'),
                            onTap: _showAddMenuDialog,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Resolve o valor exibido para cada item do menu.
  String _resolveValue(MenuItemConfig item) {
    if (item.kind == MenuItemKind.custom) {
      return item.customValue ?? '-';
    }

    final format = AppSettingsScope.of(context).currencyFormatter();
    switch (item.metric) {
      case MenuMetric.receitas:
        return format.format(widget.receitas);
      case MenuMetric.despesas:
        return format.format(widget.despesas);
      case MenuMetric.saldoMensal:
        return format.format(widget.saldoMensal);
      case MenuMetric.saldoAposReserva:
        return format.format(widget.saldoAposReserva);
      case MenuMetric.saldoAtual:
        return format.format(widget.saldoAtual);
      case MenuMetric.segurancaAno:
        return format.format(widget.segurancaAno);
      case null:
        return '-';
    }
  }

  // Resolve a cor do badge de cada indicador.
  Color _resolveColor(MenuItemConfig item) {
    if (item.kind == MenuItemKind.custom) {
      return AppThemeTokens.of(context).metricFallback;
    }

    final tokens = AppThemeTokens.of(context);
    final settings = AppSettingsScope.of(context);
    switch (item.metric) {
      case MenuMetric.receitas:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.receitas),
          tokens.metricColor(MetricColorRole.receitas),
        );
      case MenuMetric.despesas:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.despesas),
          tokens.metricColor(MetricColorRole.despesas),
        );
      case MenuMetric.saldoMensal:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.saldoMensal),
          widget.saldoMensal >= 0
              ? tokens.metricColor(MetricColorRole.saldoMensalPositivo)
              : tokens.metricColor(MetricColorRole.saldoMensalNegativo),
        );
      case MenuMetric.saldoAposReserva:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.saldoAposReserva),
          widget.saldoAposReserva >= 0
              ? tokens.metricColor(MetricColorRole.saldoAposReservaPositivo)
              : tokens.metricColor(MetricColorRole.saldoAposReservaNegativo),
        );
      case MenuMetric.saldoAtual:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.saldoAtual),
          tokens.metricColor(MetricColorRole.saldoAtual),
        );
      case MenuMetric.segurancaAno:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.segurancaAno),
          tokens.metricColor(MetricColorRole.segurancaAno),
        );
      case null:
        return tokens.metricFallback;
    }
  }

  // Resolve o titulo conforme configuracao de labels.
  String _resolveTitle(AppSettingsStore settings, MenuItemConfig item) {
    if (item.kind != MenuItemKind.metric || item.metric == null) {
      return item.title;
    }
    final defaultTitle = menuMetricTitle(item.metric!);
    if (item.title.trim() == defaultTitle) {
      return settings.labelForMetric(menuMetricKey(item.metric!), defaultTitle);
    }
    return item.title;
  }

  // Resolve a navegacao para telas de detalhe.
  VoidCallback? _resolveTap(MenuItemConfig item) {
    if (item.kind != MenuItemKind.metric) {
      return null;
    }

    switch (item.metric) {
      case MenuMetric.receitas:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceitasScreen(store: widget.receitasStore),
            ),
          );
        };
              case MenuMetric.despesas:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(
                  builder: (context) => ExpensesScreen(
                    expensesStore: widget.expensesStore,
                    entryCategoriesStore: widget.entryCategoriesStore,
                  ),
                ),
              );
            };
      case MenuMetric.saldoMensal:
      case MenuMetric.saldoAposReserva:
      case MenuMetric.saldoAtual:
      case MenuMetric.segurancaAno:
      case null:
        return null;
    }
  }

  // Exibe o dialogo para adicionar novos indicadores.
  void _showAddMenuDialog() {
    final titleController = TextEditingController();
    final valueController = TextEditingController();
    MenuItemKind kind = MenuItemKind.metric;
    MenuSectionType selectedType = MenuSectionType.receitas;
    MenuMetric selectedMetric = MenuMetric.receitas;
    final settings = AppSettingsScope.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<MenuSectionType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(
                        value: MenuSectionType.receitas,
                        child: Text('Receitas'),
                      ),
                      DropdownMenuItem(
                        value: MenuSectionType.despesas,
                        child: Text('Despesas'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedType = value;
                        if (kind == MenuItemKind.metric) {
                          selectedMetric = selectedType == MenuSectionType.receitas
                              ? MenuMetric.receitas
                              : MenuMetric.despesas;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MenuItemKind>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: MenuItemKind.metric,
                        child: Text('Indicador'),
                      ),
                      DropdownMenuItem(
                        value: MenuItemKind.custom,
                        child: Text('Personalizado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => kind = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (kind == MenuItemKind.metric)
                  DropdownButtonFormField<MenuMetric>(
                      initialValue: selectedMetric,
                      decoration: const InputDecoration(labelText: 'Indicador'),
                      items: MenuMetric.values
                          .map(
                            (metric) => DropdownMenuItem(
                              value: metric,
                              child: Text(
                                settings.labelForMetric(
                                  menuMetricKey(metric),
                                  menuMetricTitle(metric),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedMetric = value);
                      },
                    ),
                  if (kind == MenuItemKind.metric) const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titulo'),
                  ),
                  if (kind == MenuItemKind.custom) const SizedBox(height: 8),
                  if (kind == MenuItemKind.custom)
                    TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Valor'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (kind == MenuItemKind.metric) {
                      widget.menuStore.addMetricItem(
                        selectedType,
                        selectedMetric,
                        title: titleController.text.trim().isEmpty
                            ? settings.labelForMetric(
                                menuMetricKey(selectedMetric),
                                menuMetricTitle(selectedMetric),
                              )
                            : titleController.text.trim(),
                      );
                    } else {
                      if (titleController.text.trim().isEmpty ||
                          valueController.text.trim().isEmpty) {
                        return;
                      }
                      widget.menuStore.addCustomItem(
                        selectedType,
                        title: titleController.text,
                        value: valueController.text,
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Linha de item com valor, cor e acoes.
class _MenuItemRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onRemove;
  final Widget dragHandle;

  const _MenuItemRow({
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
    required this.onRemove,
    required this.dragHandle,
  });

  @override
  // Monta a UI de cada item do resumo.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.spaceSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radiusLgTight),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spaceMd,
            vertical: AppLayout.spaceMd,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppLayout.radiusLgTight),
            color: tokens.surfaceAlt,
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppLayout.radiusSm),
                ),
              ),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppLayout.spaceXs),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppLayout.spaceSm),
              dragHandle,
              const SizedBox(width: AppLayout.spaceSm),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(AppLayout.radiusMdTight),
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.spaceXs),
                  child: Icon(
                    Icons.close,
                    size: AppLayout.iconSm,
                    color: tokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card para adicionar novo item ao resumo.
class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({super.key, required this.onTap});

  @override
  // Monta o botao de adicionar item.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.radiusLgTight),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.spaceMd,
          vertical: AppLayout.spaceMd,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLayout.radiusLgTight),
          border: Border.all(color: tokens.borderStrong),
          color: tokens.surfaceAlt,
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle, size: AppLayout.iconLg, color: tokens.textPrimary),
            const SizedBox(width: AppLayout.spaceMd),
            Text(
              'Adicionar item',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
