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

class ResumoFinanceiroWidget extends StatefulWidget {
  final MenuStore menuStore;
  final ReceitasStore receitasStore;
  final DespesasStore despesasStore;
  final CategoriesStore categoriesStore;
  final double receitas;
  final double despesas;
  final double saldoMensal;
  final double saldoAposReserva;
  final double saldoAtual;
  final double segurancaAno;

  const ResumoFinanceiroWidget({
    required this.menuStore,
    required this.receitasStore,
    required this.despesasStore,
    required this.categoriesStore,
    required this.receitas,
    required this.despesas,
    required this.saldoMensal,
    required this.saldoAposReserva,
    required this.saldoAtual,
    required this.segurancaAno,
    super.key,
  });

  @override
  State<ResumoFinanceiroWidget> createState() => _ResumoFinanceiroWidgetState();
}

class _ResumoFinanceiroWidgetState extends State<ResumoFinanceiroWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return AnimatedBuilder(
      animation: widget.menuStore,
      builder: (context, _) {
        return ExpansionPanelList(
          elevation: 0,
          dividerColor: Colors.white.withValues(alpha: 0.1),
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          children: [
            ExpansionPanel(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              isExpanded: _isExpanded,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    'Resumo Financeiro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Arraste para ordenar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: widget.menuStore.orderedItems.length + 1,
                        onReorder: widget.menuStore.reorderOrderedItems,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        itemBuilder: (context, index) {
                          if (index < widget.menuStore.orderedItems.length) {
                            final entry = widget.menuStore.orderedItems[index];
                            return _MenuItemRow(
                        key: ValueKey(entry.item.id),
                        title: _resolveTitle(settings, entry.item),
                        value: _resolveValue(entry.item),
                        color: _resolveColor(entry.item),
                              onTap: _resolveTap(entry.item),
                              onRemove: () =>
                                  widget.menuStore.removeItem(entry.type, entry.item.id),
                              dragHandle: ReorderableDelayedDragStartListener(
                                index: index,
                                child: Tooltip(
                                  message: 'Arrastar para reordenar',
                                  child: Container(
                                    height: 24,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.drag_indicator,
                                      size: 14,
                                      color: Colors.white70,
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

  Color _resolveColor(MenuItemConfig item) {
    if (item.kind == MenuItemKind.custom) {
      return const Color(0xFF254A6A);
    }

    final settings = AppSettingsScope.of(context);
    switch (item.metric) {
      case MenuMetric.receitas:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.receitas),
          const Color(0xFF1FAF86),
        );
      case MenuMetric.despesas:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.despesas),
          const Color(0xFF2A2D3C),
        );
      case MenuMetric.saldoMensal:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.saldoMensal),
          widget.saldoMensal >= 0 ? const Color(0xFF1C8EC9) : const Color(0xFFE19932),
        );
      case MenuMetric.saldoAposReserva:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.saldoAposReserva),
          widget.saldoAposReserva >= 0 ? const Color(0xFF1D9C7C) : const Color(0xFFE36A4F),
        );
      case MenuMetric.saldoAtual:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.saldoAtual),
          const Color(0xFF1C7C9C),
        );
      case MenuMetric.segurancaAno:
        return settings.colorForMetric(
          menuMetricKey(MenuMetric.segurancaAno),
          const Color(0xFF3D5BA9),
        );
      case null:
        return const Color(0xFF254A6A);
    }
  }

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
              builder: (context) => DespesasScreen(
                store: widget.despesasStore,
                categoriesStore: widget.categoriesStore,
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

class _MenuItemRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onRemove;
  final Widget dragHandle;

  const _MenuItemRow({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
    required this.onRemove,
    required this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              dragHandle,
              const SizedBox(width: 8),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
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

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Adicionar item',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
