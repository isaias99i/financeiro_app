import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../data/categories_store.dart';
import '../models/despesas_models.dart';
import '../screens/categorias_screen.dart';
import '../screens/despesa_coluna_screen.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_badge.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/app_settings_scope.dart';

class DespesasScreen extends StatefulWidget {
  final DespesasStore store;
  final CategoriesStore categoriesStore;

  const DespesasScreen({
    super.key,
    required this.store,
    required this.categoriesStore,
  });

  @override
  State<DespesasScreen> createState() => _DespesasScreenState();
}

class _DespesasScreenState extends State<DespesasScreen> {
  static final DateTime _startDate = DateTime(2026, 1, 1);

  final Map<String, TextEditingController> _simpleControllers = {};
  late DateTime _selectedMonth;
  late PageController _monthController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    if (!widget.store.isLoaded) {
      widget.store.load();
    }
    if (!widget.categoriesStore.isLoaded) {
      widget.categoriesStore.load();
    }
    _selectedMonth = _initialMonth();
    _currentIndex = _monthsBetween(_startDate, _selectedMonth);
    _monthController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    for (final controller in _simpleControllers.values) {
      controller.dispose();
    }
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final monthFormatter = settings.monthYearFormatter();
    final moneyFormatter = settings.currencyFormatter();

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [
          IconButton(
            onPressed: _openCategories,
            icon: const Icon(Icons.category),
            tooltip: 'Categorias',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          if (!widget.store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalMes = widget.store.totalForMonth(_selectedMonth);
          final groupCount = widget.store.groups.length;
          final columnCount = widget.store.groups.fold<int>(
            0,
            (sum, group) => sum + group.columns.length,
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthSelector(
                  controller: _monthController,
                  formatter: monthFormatter,
                  onPrevious: _canGoPrevious() ? _previousMonth : null,
                  onNext: _nextMonth,
                  onChanged: (index) {
                    setState(() {
                      _setSelectedMonth(index);
                    });
                  },
                ),
                const SizedBox(height: 10),
                _SummaryCard(
                  totalLabel: moneyFormatter.format(totalMes),
                  groupCount: groupCount,
                  columnCount: columnCount,
                ),
                const SizedBox(height: 12),
                _ActionBar(
                  onAddGroup: _addGroup,
                  onAddColumn: widget.store.groups.isEmpty ? null : _addColumn,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: widget.store.groups.isEmpty
                      ? _EmptyState(onAddGroup: _addGroup)
                      : ListView.separated(
                          itemCount: widget.store.groups.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final group = widget.store.groups[index];
                            final groupTotal = widget.store.totalForGroup(_selectedMonth, group);

                            return _GroupCard(
                              group: group,
                              totalLabel: moneyFormatter.format(groupTotal),
                              onEditGroup: () => _editGroup(group),
                              onRemoveGroup: () => _removeGroup(group),
                              onAddColumn: () => _addColumnForGroup(group),
                              onEditColumn: (column) => _editColumn(group, column),
                              onRemoveColumn: (column) => _removeColumn(group, column),
                              columnCount: group.columns.length,
                              buildCell: (column) {
                                if (!column.requiresEntries) {
                                  return _ColumnValueTile(
                                    title: column.title,
                                    controller: _simpleControllerFor(
                                      _selectedMonth,
                                      column,
                                      moneyFormatter,
                                    ),
                                    onChanged: (value) =>
                                        _updateSimpleValueCurrent(_selectedMonth, column, value),
                                    onApply: (value) =>
                                        _applyFixedValueFromMonth(_selectedMonth, column, value),
                                    badgeLabel: 'valor fixo',
                                  );
                                }

                                final total = widget.store.totalForColumn(_selectedMonth, column);
                                final count =
                                    widget.store.countForColumn(_selectedMonth, column);
                                return _ColumnSummaryTile(
                                  title: column.title,
                                  totalLabel: moneyFormatter.format(total),
                                  countLabel: '$count itens',
                                  onTap: () => _openColumnEntries(group, column),
                                  badgeLabel: 'detalhado',
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                _TotalFooter(
                  label: moneyFormatter.format(totalMes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  DateTime _initialMonth() {
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, 1);
    if (normalized.isBefore(_startDate)) {
      return _startDate;
    }
    return normalized;
  }

  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  DateTime _monthFromIndex(int index) {
    return DateTime(_startDate.year, _startDate.month + index, 1);
  }

  bool _canGoPrevious() => _currentIndex > 0;

  void _previousMonth() {
    if (!_canGoPrevious()) return;
    _monthController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _nextMonth() {
    _monthController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _setSelectedMonth(int index) {
    _currentIndex = index;
    _selectedMonth = _monthFromIndex(index);
    _resetSimpleControllers();
  }

  void _resetSimpleControllers() {
    for (final controller in _simpleControllers.values) {
      controller.dispose();
    }
    _simpleControllers.clear();
  }

  void _openColumnEntries(ExpenseGroup group, ExpenseColumn column) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DespesaColunaScreen(
          store: widget.store,
          categoriesStore: widget.categoriesStore,
          group: group,
          column: column,
          initialMonth: _selectedMonth,
        ),
      ),
    );
  }

  void _openCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasScreen(store: widget.categoriesStore),
      ),
    );
  }

  TextEditingController _simpleControllerFor(
    DateTime month,
    ExpenseColumn column,
    NumberFormat formatter,
  ) {
    final key = '${monthKey(month)}|${column.id}';
    return _simpleControllers.putIfAbsent(key, () {
      final controller = TextEditingController();
      final value = widget.store.valueForColumn(month, column);
      if (value > 0) {
        controller.text = formatter.format(value);
      }
      return controller;
    });
  }

  void _applyFixedValueFromMonth(DateTime month, ExpenseColumn column, String value) {
    final parsed = parseCurrencyToDouble(value);
    final settings = AppSettingsScope.of(context);
    final formatter = settings.currencyFormatter();
    final end = DateTime(2030, 12, 1);
    widget.store.setFixedValueFromMonth(month, end, column, parsed);

    _simpleControllers.forEach((key, controller) {
      final parts = key.split('|');
      if (parts.length != 2 || parts[1] != column.id) {
        return;
      }
      final parsedMonth = parseMonthKey(parts[0]);
      if (parsedMonth == null || parsedMonth.isBefore(month)) {
        return;
      }
      controller.text = formatter.format(parsed);
    });
  }

  void _updateSimpleValueCurrent(DateTime month, ExpenseColumn column, String value) {
    final parsed = parseCurrencyToDouble(value);
    widget.store.setValueForColumn(month, column, parsed);
  }

  Future<void> _addGroup() async {
    final title = await _promptForText(
      title: 'Novo grupo',
      label: 'Nome do grupo',
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.addGroup(title.trim());
    _showSnack('Grupo criado');
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
    widget.store.addColumn(
      result.group,
      result.title,
      requiresEntries: result.requiresEntries,
    );
    _showSnack('Coluna adicionada');
  }

  Future<void> _addColumnForGroup(ExpenseGroup group) async {
    final result = await _promptForColumn(group: group);
    if (result == null) return;
    widget.store.addColumn(
      group,
      result.title,
      requiresEntries: result.requiresEntries,
    );
    _showSnack('Coluna adicionada');
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
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            enableSuggestions: true,
            autocorrect: true,
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

  Future<_ColumnInput?> _promptForColumn({ExpenseGroup? group}) async {
    final controller = TextEditingController();
    ExpenseGroup selectedGroup = group ?? widget.store.groups.first;
    bool requiresEntries = true;

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
                  if (group == null)
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
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    enableSuggestions: true,
                    autocorrect: true,
                    decoration: const InputDecoration(labelText: 'Nome da coluna'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Registrar lançamentos detalhados'),
                    subtitle: const Text('Usar data, categoria, motivo e valor'),
                    value: requiresEntries,
                    onChanged: (value) {
                      setState(() => requiresEntries = value);
                    },
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
                    Navigator.pop(
                      context,
                      _ColumnInput(
                        selectedGroup,
                        title,
                        requiresEntries: requiresEntries,
                      ),
                    );
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}

class _ColumnInput {
  _ColumnInput(
    this.group,
    this.title, {
    required this.requiresEntries,
  });

  final ExpenseGroup group;
  final String title;
  final bool requiresEntries;
}

class _MonthSelector extends StatelessWidget {
  final PageController controller;
  final DateFormat formatter;
  final void Function(int index) onChanged;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.controller,
    required this.formatter,
    required this.onChanged,
    this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C8EC9).withValues(alpha: 0.18),
            const Color(0xFF1FAF86).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 28,
              child: PageView.builder(
                controller: controller,
                onPageChanged: onChanged,
                itemBuilder: (context, index) {
                  final month = DateTime(2026, 1 + index, 1);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatter.format(month),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
            tooltip: 'Mes anterior',
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
            tooltip: 'Proximo mes',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddGroup;

  const _EmptyState({required this.onAddGroup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Nenhum grupo criado. Crie um grupo para começar.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddGroup,
              icon: const Icon(Icons.add),
              label: const Text('Criar grupo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String totalLabel;
  final int groupCount;
  final int columnCount;

  const _SummaryCard({
    required this.totalLabel,
    required this.groupCount,
    required this.columnCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF19344A).withValues(alpha: 0.55),
            const Color(0xFF0F2C3E).withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total do mes',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  totalLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          AuroraBadge(label: '$groupCount grupos'),
          const SizedBox(width: 6),
          AuroraBadge(label: '$columnCount colunas'),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onAddGroup;
  final VoidCallback? onAddColumn;

  const _ActionBar({
    required this.onAddGroup,
    required this.onAddColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddGroup,
            icon: const Icon(Icons.add),
            label: const Text('Novo grupo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddColumn,
            icon: const Icon(Icons.view_column),
            label: const Text('Nova coluna'),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final ExpenseGroup group;
  final String totalLabel;
  final VoidCallback onEditGroup;
  final VoidCallback onRemoveGroup;
  final VoidCallback onAddColumn;
  final void Function(ExpenseColumn column) onEditColumn;
  final void Function(ExpenseColumn column) onRemoveColumn;
  final int columnCount;
  final Widget Function(ExpenseColumn column) buildCell;

  const _GroupCard({
    required this.group,
    required this.totalLabel,
    required this.onEditGroup,
    required this.onRemoveGroup,
    required this.onAddColumn,
    required this.onEditColumn,
    required this.onRemoveColumn,
    required this.columnCount,
    required this.buildCell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$columnCount colunas',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 8),
              Text(
                totalLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAddColumn,
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar coluna',
                color: Colors.white70,
              ),
              IconButton(
                onPressed: onEditGroup,
                icon: const Icon(Icons.edit),
                tooltip: 'Editar grupo',
                color: Colors.white70,
              ),
              IconButton(
                onPressed: onRemoveGroup,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover grupo',
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (group.columns.isEmpty)
            const Text(
              'Sem colunas. Clique em adicionar para incluir.',
              style: TextStyle(color: Colors.white70),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 900
                    ? 3
                    : width >= 600
                        ? 2
                        : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.columns.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final column = group.columns[index];
                    return Stack(
                      children: [
                        buildCell(column),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Row(
                            children: [
                              _TinyIconButton(
                                icon: Icons.edit,
                                onTap: () => onEditColumn(column),
                              ),
                              _TinyIconButton(
                                icon: Icons.close,
                                onTap: () => onRemoveColumn(column),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ColumnSummaryTile extends StatelessWidget {
  final String title;
  final String totalLabel;
  final String countLabel;
  final VoidCallback onTap;
  final String? badgeLabel;

  const _ColumnSummaryTile({
    required this.title,
    required this.totalLabel,
    required this.countLabel,
    required this.onTap,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              totalLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  countLabel,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
                if (badgeLabel != null) ...[
                  const SizedBox(width: 8),
                  AuroraBadge(
                    label: badgeLabel!,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    fontSize: 10,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnValueTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onApply;
  final String? badgeLabel;

  const _ColumnValueTile({
    required this.title,
    required this.controller,
    required this.onChanged,
    required this.onApply,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                onApply(controller.text);
              }
            },
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                CurrencyInputFormatter(
                  locale: settings.currencyLocale,
                  symbol: settings.currencySymbol,
                ),
              ],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '0,00',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              onChanged: (value) {
                onChanged(value);
                onApply(value);
              },
              onEditingComplete: () => onApply(controller.text),
              onSubmitted: (_) => onApply(controller.text),
            ),
          ),
          if (badgeLabel != null) ...[
            const SizedBox(height: 6),
            AuroraBadge(
              label: badgeLabel!,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              fontSize: 10,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  final String label;

  const _TotalFooter({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text(
            'Total do mes',
            style: TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TinyIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }
}
