import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/menu_store.dart';
import '../data/despesas_store.dart';
import '../data/receitas_store.dart';
import '../models/menu_models.dart';
import '../screens/despesas_screen.dart';
import '../screens/receitas_screen.dart';

class ResumoFinanceiroWidget extends StatefulWidget {
  final MenuStore menuStore;
  final ReceitasStore receitasStore;
  final DespesasStore despesasStore;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.menuStore.sections.map((section) {
                    return _MenuSection(
                      title: section.title,
                      items: section.items,
                      onAdd: () => _showAddMenuDialog(section.type),
                      onRemove: (id) => widget.menuStore.removeItem(section.type, id),
                      resolveValue: _resolveValue,
                      resolveColor: _resolveColor,
                      onTap: _resolveTap,
                    );
                  }).toList(),
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

    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
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

    switch (item.metric) {
      case MenuMetric.receitas:
        return const Color(0xFF1FAF86);
      case MenuMetric.despesas:
        return const Color(0xFF2A2D3C);
      case MenuMetric.saldoMensal:
        return widget.saldoMensal >= 0 ? const Color(0xFF1C8EC9) : const Color(0xFFE19932);
      case MenuMetric.saldoAposReserva:
        return widget.saldoAposReserva >= 0 ? const Color(0xFF1D9C7C) : const Color(0xFFE36A4F);
      case MenuMetric.saldoAtual:
        return const Color(0xFF1C7C9C);
      case MenuMetric.segurancaAno:
        return const Color(0xFF3D5BA9);
      case null:
        return const Color(0xFF254A6A);
    }
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
              builder: (context) => DespesasScreen(store: widget.despesasStore),
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

  void _showAddMenuDialog(MenuSectionType type) {
    final titleController = TextEditingController();
    final valueController = TextEditingController();
    MenuItemKind kind = MenuItemKind.metric;
    MenuMetric selectedMetric =
        type == MenuSectionType.receitas ? MenuMetric.receitas : MenuMetric.despesas;

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
                              child: Text(menuMetricTitle(metric)),
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
                        type,
                        selectedMetric,
                        title: titleController.text.trim().isEmpty
                            ? menuMetricTitle(selectedMetric)
                            : titleController.text.trim(),
                      );
                    } else {
                      if (titleController.text.trim().isEmpty ||
                          valueController.text.trim().isEmpty) {
                        return;
                      }
                      widget.menuStore.addCustomItem(
                        type,
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

class _MenuSection extends StatelessWidget {
  final String title;
  final List<MenuItemConfig> items;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final String Function(MenuItemConfig item) resolveValue;
  final Color Function(MenuItemConfig item) resolveColor;
  final VoidCallback? Function(MenuItemConfig item) onTap;

  const _MenuSection({
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.resolveValue,
    required this.resolveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
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
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.drag_indicator, size: 14, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 900
                    ? 4
                    : width >= 640
                        ? 3
                        : 2;
                final childAspectRatio = width >= 640 ? 1.55 : 1.35;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length + 1,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    if (index < items.length) {
                      final item = items[index];
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: FinanceCard(
                              title: item.title,
                              value: resolveValue(item),
                              color: resolveColor(item),
                              onTap: onTap(item),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: InkWell(
                              onTap: () => onRemove(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return _AddCard(onTap: onAdd);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: const Center(
          child: Icon(Icons.add_circle, size: 36, color: Colors.white),
        ),
      ),
    );
  }
}

class FinanceCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const FinanceCard({
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.6),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
