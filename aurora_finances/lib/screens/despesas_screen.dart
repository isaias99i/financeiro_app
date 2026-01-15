import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_scaffold.dart';

class DespesasScreen extends StatefulWidget {
  final DespesasStore store;

  const DespesasScreen({super.key, required this.store});

  @override
  State<DespesasScreen> createState() => _DespesasScreenState();
}

class _DespesasScreenState extends State<DespesasScreen> {
  static final DateTime _startDate = DateTime(2026, 1, 1);
  static final DateTime _endDate = DateTime(2030, 12, 1);
  static const double _colWidth = 140;
  static const double _rowHeight = 40;
  static const double _monthColWidth = 120;
  static const double _totalColWidth = 140;

  final Map<String, TextEditingController> _valueControllers = {};

  @override
  void initState() {
    super.initState();
    if (!widget.store.isLoaded) {
      widget.store.load();
    }
  }

  @override
  void dispose() {
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _buildMonths();
    final monthFormatter = DateFormat('MM/yyyy');
    final moneyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          if (!widget.store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar grupo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.store.groups.isEmpty ? null : _addColumn,
                      icon: const Icon(Icons.view_column),
                      label: const Text('Adicionar coluna'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.store.groups.isEmpty)
                  const Text(
                    'Nenhum grupo criado. Adicione um grupo para comecar.',
                    style: TextStyle(color: Colors.white),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MonthColumn(
                            months: months.map(monthFormatter.format).toList(),
                            rowHeight: _rowHeight,
                            width: _monthColWidth,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _GroupHeaderRow(
                                    groups: widget.store.groups,
                                    colWidth: _colWidth,
                                    rowHeight: _rowHeight,
                                    onEditGroup: _editGroup,
                                    onRemoveGroup: _removeGroup,
                                  ),
                                  _ColumnHeaderRow(
                                    groups: widget.store.groups,
                                    colWidth: _colWidth,
                                    rowHeight: _rowHeight,
                                    onEditColumn: _editColumn,
                                    onRemoveColumn: _removeColumn,
                                  ),
                                  ...months.map((month) {
                                    return _DataRow(
                                      groups: widget.store.groups,
                                      colWidth: _colWidth,
                                      rowHeight: _rowHeight,
                                      controllerFor: (column) =>
                                          _controllerFor(month, column, moneyFormatter),
                                      onChanged: (column, value) =>
                                          _updateValue(month, column, value),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _TotalColumn(
                            totals: months
                                .map((month) => widget.store.totalForMonth(month))
                                .toList(),
                            rowHeight: _rowHeight,
                            width: _totalColWidth,
                            formatter: moneyFormatter,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DateTime> _buildMonths() {
    final months = <DateTime>[];
    var current = _startDate;
    while (!current.isAfter(_endDate)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return months;
  }

  TextEditingController _controllerFor(
    DateTime month,
    ExpenseColumn column,
    NumberFormat formatter,
  ) {
    final key = '${monthKey(month)}|${column.id}';
    return _valueControllers.putIfAbsent(key, () {
      final controller = TextEditingController();
      final value = widget.store.valueForCell(month, column);
      if (value > 0) {
        controller.text = formatter.format(value);
      }
      return controller;
    });
  }

  void _updateValue(DateTime month, ExpenseColumn column, String value) {
    final parsed = parseCurrencyToDouble(value);
    widget.store.setValueForCell(month, column, parsed);
  }

  Future<void> _addGroup() async {
    final title = await _promptForText(
      title: 'Novo grupo',
      label: 'Nome do grupo',
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.addGroup(title.trim());
  }

  Future<void> _editGroup(ExpenseGroup group) async {
    final title = await _promptForText(
      title: 'Editar grupo',
      label: 'Nome do grupo',
      initialValue: group.title,
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.updateGroup(group, title.trim());
  }

  void _removeGroup(ExpenseGroup group) {
    widget.store.removeGroup(group);
  }

  Future<void> _addColumn() async {
    final result = await _promptForColumn();
    if (result == null) return;
    widget.store.addColumn(result.group, result.title);
  }

  Future<void> _editColumn(ExpenseGroup group, ExpenseColumn column) async {
    final title = await _promptForText(
      title: 'Editar coluna',
      label: 'Nome da coluna',
      initialValue: column.title,
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.updateColumn(group, column, title.trim());
  }

  void _removeColumn(ExpenseGroup group, ExpenseColumn column) {
    widget.store.removeColumn(group, column);
  }

  Future<String?> _promptForText({
    required String title,
    required String label,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<_ColumnInput?> _promptForColumn() async {
    final controller = TextEditingController();
    ExpenseGroup selectedGroup = widget.store.groups.first;

    return showDialog<_ColumnInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova coluna'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ExpenseGroup>(
                    initialValue: selectedGroup,
                    decoration: const InputDecoration(labelText: 'Grupo'),
                    items: widget.store.groups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedGroup = value);
                    },
                  ),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Nome da coluna'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = controller.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(context, _ColumnInput(selectedGroup, title));
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

class _ColumnInput {
  _ColumnInput(this.group, this.title);

  final ExpenseGroup group;
  final String title;
}

class _MonthColumn extends StatelessWidget {
  const _MonthColumn({
    required this.months,
    required this.rowHeight,
    required this.width,
  });

  final List<String> months;
  final double rowHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderCell(
          width: width,
          height: rowHeight * 2,
          label: 'Mes',
        ),
        ...months.map((month) {
          return _ValueCell(
            width: width,
            height: rowHeight,
            label: month,
            align: TextAlign.center,
          );
        }),
      ],
    );
  }
}

class _TotalColumn extends StatelessWidget {
  const _TotalColumn({
    required this.totals,
    required this.rowHeight,
    required this.width,
    required this.formatter,
  });

  final List<double> totals;
  final double rowHeight;
  final double width;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderCell(
          width: width,
          height: rowHeight * 2,
          label: 'Total',
        ),
        ...totals.map((value) {
          return _ValueCell(
            width: width,
            height: rowHeight,
            label: formatter.format(value),
          );
        }),
      ],
    );
  }
}

class _GroupHeaderRow extends StatelessWidget {
  const _GroupHeaderRow({
    required this.groups,
    required this.colWidth,
    required this.rowHeight,
    required this.onEditGroup,
    required this.onRemoveGroup,
  });

  final List<ExpenseGroup> groups;
  final double colWidth;
  final double rowHeight;
  final void Function(ExpenseGroup group) onEditGroup;
  final void Function(ExpenseGroup group) onRemoveGroup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: groups.map((group) {
        final spanWidth = colWidth * (group.columns.isEmpty ? 1 : group.columns.length);
        return _HeaderCell(
          width: spanWidth,
          height: rowHeight,
          label: group.title,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIcon(
                icon: Icons.edit,
                onTap: () => onEditGroup(group),
              ),
              _HeaderIcon(
                icon: Icons.close,
                onTap: () => onRemoveGroup(group),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ColumnHeaderRow extends StatelessWidget {
  const _ColumnHeaderRow({
    required this.groups,
    required this.colWidth,
    required this.rowHeight,
    required this.onEditColumn,
    required this.onRemoveColumn,
  });

  final List<ExpenseGroup> groups;
  final double colWidth;
  final double rowHeight;
  final void Function(ExpenseGroup group, ExpenseColumn column) onEditColumn;
  final void Function(ExpenseGroup group, ExpenseColumn column) onRemoveColumn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final group in groups)
          if (group.columns.isEmpty)
            _HeaderCell(
              width: colWidth,
              height: rowHeight,
              label: 'Sem colunas',
            )
          else
            for (final column in group.columns)
              _HeaderCell(
                width: colWidth,
                height: rowHeight,
                label: column.title,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderIcon(
                      icon: Icons.edit,
                      onTap: () => onEditColumn(group, column),
                    ),
                    _HeaderIcon(
                      icon: Icons.close,
                      onTap: () => onRemoveColumn(group, column),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.groups,
    required this.colWidth,
    required this.rowHeight,
    required this.controllerFor,
    required this.onChanged,
  });

  final List<ExpenseGroup> groups;
  final double colWidth;
  final double rowHeight;
  final TextEditingController Function(ExpenseColumn column) controllerFor;
  final void Function(ExpenseColumn column, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final group in groups)
          if (group.columns.isEmpty)
            _ValueCell(width: colWidth, height: rowHeight, label: '-')
          else
            for (final column in group.columns)
              _InputCell(
                width: colWidth,
                height: rowHeight,
                controller: controllerFor(column),
                onChanged: (value) => onChanged(column, value),
              ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.width,
    required this.height,
    required this.label,
    this.trailing,
  });

  final double width;
  final double height;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.width,
    required this.height,
    required this.label,
    this.align = TextAlign.right,
  });

  final double width;
  final double height;
  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _InputCell extends StatelessWidget {
  const _InputCell({
    required this.width,
    required this.height,
    required this.controller,
    required this.onChanged,
  });

  final double width;
  final double height;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          CurrencyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
        ],
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: '0,00',
          hintStyle: TextStyle(color: Colors.white54),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }
}
