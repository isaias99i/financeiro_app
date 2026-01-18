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
import '../theme/app_layout.dart';
import '../theme/app_tokens.dart';

// Tela de despesas com categorias e itens de gasto.
class DespesasScreen extends StatefulWidget {
  final DespesasStore store;
  final CategoriesStore categoriesStore;

  const DespesasScreen({
    super.key,
    required this.store,
    required this.categoriesStore,
  });

  @override
  // Cria o estado da tela de despesas.
  State<DespesasScreen> createState() => _DespesasScreenState();
}

// Estado da tela de despesas com navegacao de meses.
class _DespesasScreenState extends State<DespesasScreen> {
  static final DateTime _startDate = DateTime(2026, 1, 1);

  final Map<String, TextEditingController> _simpleControllers = {};
  late DateTime _selectedMonth;
  late PageController _monthController;
  late int _currentIndex;

  @override
  // Inicializa stores e o controle de meses.
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
  // Libera controllers usados na tela.
  void dispose() {
    for (final controller in _simpleControllers.values) {
      controller.dispose();
    }
    _monthController.dispose();
    super.dispose();
  }

  @override
  // Monta a UI com categorias, itens de gasto e totalizadores.
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
            padding: const EdgeInsets.all(AppLayout.spaceLg),
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
                const SizedBox(height: AppLayout.spaceMd),
                _SummaryCard(
                  totalLabel: moneyFormatter.format(totalMes),
                  groupCount: groupCount,
                  columnCount: columnCount,
                ),
                _ActionIcons(
                  onAddCategory: _addGroup,
                  onAddSubcategory: _addColumn,
                  canAddSubcategory: widget.store.groups.isNotEmpty,
                ),
                const SizedBox(height: AppLayout.spaceSm),
                Expanded(
                  child: widget.store.groups.isEmpty
                      ? _EmptyState(onAddGroup: _addGroup)
                      : ReorderableListView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          buildDefaultDragHandles: false,
                          // Mantem o item arrastado sem fundo escuro, com sombra sutil.
                          proxyDecorator: (child, index, animation) {
                            return Builder(
                              builder: (context) {
                                final tokens = AppThemeTokens.of(context);
                                return Material(
                                  color: Colors.transparent,
                                  elevation: 4,
                                  shadowColor: tokens.shadow,
                                  borderRadius: BorderRadius.circular(
                                    AppLayout.radiusLg,
                                  ),
                                  child: child,
                                );
                              },
                            );
                          },
                          itemCount: widget.store.groups.length,
                          onReorder: widget.store.reorderGroups,
                          itemBuilder: (context, index) {
                            final group = widget.store.groups[index];
                            final groupTotal = widget.store.totalForGroup(
                              _selectedMonth,
                              group,
                            );

                            return Padding(
                              key: ValueKey(group.id),
                              padding: const EdgeInsets.only(
                                bottom: AppLayout.spaceMd,
                              ),
                              child: _GroupCard(
                                group: group,
                                totalLabel: moneyFormatter.format(groupTotal),
                                onEditGroup: () => _editGroup(group),
                                onRemoveGroup: () => _removeGroup(group),
                                onAddColumn: () => _addColumnForGroup(group),
                                onEditColumn: (column) =>
                                    _editColumn(group, column),
                                onRemoveColumn: (column) =>
                                    _removeColumn(group, column),
                                onReorderColumns: (oldIndex, newIndex) =>
                                    widget.store.reorderColumns(
                                      group,
                                      oldIndex,
                                      newIndex,
                                    ),
                                dragHandle: ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_indicator),
                                ),
                                buildCell: (column, columnIndex) {
                                  if (!column.requiresEntries) {
                                    return _ColumnValueTile(
                                      title: column.title,
                                      controller: _simpleControllerFor(
                                        _selectedMonth,
                                        column,
                                        moneyFormatter,
                                      ),
                                      onChanged: (value) =>
                                          _updateSimpleValueCurrent(
                                            _selectedMonth,
                                            column,
                                            value,
                                          ),
                                      onApply: (value) =>
                                          _applyFixedValueFromMonth(
                                            _selectedMonth,
                                            column,
                                            value,
                                          ),
                                    );
                                  }

                                  final total = widget.store.totalForColumn(
                                    _selectedMonth,
                                    column,
                                  );
                                  final count = widget.store.countForColumn(
                                    _selectedMonth,
                                    column,
                                  );
                                  return _ColumnSummaryTile(
                                    title: column.title,
                                    totalLabel: moneyFormatter.format(total),
                                    countLabel: '$count itens',
                                    onTap: () =>
                                        _openColumnEntries(group, column),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppLayout.spaceMd),
                _TotalFooter(label: moneyFormatter.format(totalMes)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Define o mes inicial exibido.
  DateTime _initialMonth() {
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, 1);
    if (normalized.isBefore(_startDate)) {
      return _startDate;
    }
    return normalized;
  }

  // Calcula o deslocamento em meses.
  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  // Converte indice em data do mes.
  DateTime _monthFromIndex(int index) {
    return DateTime(_startDate.year, _startDate.month + index, 1);
  }

  // Indica se e possivel voltar um mes.
  bool _canGoPrevious() => _currentIndex > 0;

  // Navega para o mes anterior.
  void _previousMonth() {
    if (!_canGoPrevious()) return;
    _monthController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // Navega para o proximo mes.
  void _nextMonth() {
    _monthController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // Atualiza o mes selecionado e reseta inputs.
  void _setSelectedMonth(int index) {
    _currentIndex = index;
    _selectedMonth = _monthFromIndex(index);
    _resetSimpleControllers();
  }

  // Reseta os controllers de valores fixos.
  void _resetSimpleControllers() {
    for (final controller in _simpleControllers.values) {
      controller.dispose();
    }
    _simpleControllers.clear();
  }

  // Abre a tela de lancamentos da subcategoria.
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

  // Abre a tela de categorias.
  void _openCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasScreen(store: widget.categoriesStore),
      ),
    );
  }

  // Retorna controller para subcategoria fixa por mes.
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

  // Aplica valor fixo a partir de um mes.
  void _applyFixedValueFromMonth(
    DateTime month,
    ExpenseColumn column,
    String value,
  ) {
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

  // Atualiza valor simples da subcategoria no mes.
  void _updateSimpleValueCurrent(
    DateTime month,
    ExpenseColumn column,
    String value,
  ) {
    final parsed = parseCurrencyToDouble(value);
    widget.store.setValueForColumn(month, column, parsed);
  }

  // Cria uma nova categoria de despesas.
  Future<void> _addGroup() async {
    final title = await _promptForText(
      title: 'Nova categoria',
      label: 'Nome da categoria',
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.addGroup(title.trim());
    _showSnack('Categoria criada');
  }

  // Edita o nome da categoria.
  Future<void> _editGroup(ExpenseGroup group) async {
    final title = await _promptForText(
      title: 'Editar categoria',
      label: 'Nome da categoria',
      initialValue: group.title,
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.updateGroup(group, title.trim());
  }

  // Remove uma categoria e seus itens de gasto.
  void _removeGroup(ExpenseGroup group) {
    widget.store.removeGroup(group);
  }

  // Cria uma nova subcategoria em uma categoria.
  Future<void> _addColumn() async {
    final result = await _promptForColumn();
    if (result == null) return;
    widget.store.addColumn(
      result.group,
      result.title,
      requiresEntries: result.requiresEntries,
    );
    _showSnack('Subcategoria adicionada');
  }

  // Cria uma nova subcategoria para uma categoria especifica.
  Future<void> _addColumnForGroup(ExpenseGroup group) async {
    final result = await _promptForColumn(group: group);
    if (result == null) return;
    widget.store.addColumn(
      group,
      result.title,
      requiresEntries: result.requiresEntries,
    );
    _showSnack('Subcategoria adicionada');
  }

  // Edita o titulo da subcategoria.
  Future<void> _editColumn(ExpenseGroup group, ExpenseColumn column) async {
    final title = await _promptForText(
      title: 'Editar subcategoria',
      label: 'Nome da subcategoria',
      initialValue: column.title,
    );
    if (title == null || title.trim().isEmpty) return;
    widget.store.updateColumn(group, column, title.trim());
  }

  // Remove uma subcategoria de uma categoria.
  void _removeColumn(ExpenseGroup group, ExpenseColumn column) {
    widget.store.removeColumn(group, column);
  }

  // Exibe um dialogo simples de texto.
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

  // Exibe dialogo para criar subcategoria.
  Future<_ColumnInput?> _promptForColumn({ExpenseGroup? group}) async {
    final controller = TextEditingController();
    ExpenseGroup selectedGroup = group ?? widget.store.groups.first;
    bool requiresEntries = false;

    return showDialog<_ColumnInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {            
            return AlertDialog(
              title: const Text('Nova subcategoria'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ExpenseGroup>(
                      initialValue: selectedGroup,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.folder_open),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppLayout.spaceSm,
                        ),
                      ),
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
                  const SizedBox(height: AppLayout.spaceSm),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    enableSuggestions: true,
                    autocorrect: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.subdirectory_arrow_right),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppLayout.spaceSm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceSm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Registrar lançamentos detalhados'),
                    subtitle: const Text(
                      'Usar data, categoria, motivo e valor',
                    ),
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

  // Exibe um snackbar com feedback rapido.
  void _showSnack(String message) {
    final tokens = AppThemeTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.surfaceStrong,
      ),
    );
  }
}

// Modelo interno para criar itens de gasto.
class _ColumnInput {
  _ColumnInput(this.group, this.title, {required this.requiresEntries});

  final ExpenseGroup group;
  final String title;
  final bool requiresEntries;
}

// Seletor de mes com paginação.
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
  // Monta o seletor de mes.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceMd,
        vertical: AppLayout.spaceMd,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.heroGradient,
        ),
        borderRadius: BorderRadius.circular(AppLayout.radiusLgTight),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: AppLayout.iconSm,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: AppLayout.spaceSm),
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
                      style: TextStyle(
                        color: tokens.textPrimary,
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
            color: tokens.textPrimary,
            tooltip: 'Mes anterior',
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: tokens.textPrimary,
            tooltip: 'Proximo mes',
          ),
        ],
      ),
    );
  }
}

// Estado vazio quando nao ha categorias.
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddGroup;

  const _EmptyState({required this.onAddGroup});

  @override
  // Monta o estado vazio com CTA.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppLayout.spaceLg),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(AppLayout.radiusLg),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, color: tokens.textSecondary, size: 32),
            const SizedBox(height: AppLayout.spaceSm),
            Text(
              'Nenhuma categoria criada. Crie uma categoria para começar.',
              style: TextStyle(color: tokens.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppLayout.spaceSm),
            TextButton.icon(
              onPressed: onAddGroup,
              icon: const Icon(Icons.add),
              label: const Text('Criar categoria'),
            ),
          ],
        ),
      ),
    );
  }
}

// Card com resumo do mes e contadores.
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
  // Monta o card de resumo.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceLgTight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.panelGradient,
        ),
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments, color: tokens.textSecondary),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total do mes',
                      style: TextStyle(color: tokens.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: AppLayout.spaceXs),
                    Text(
                      totalLabel,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceSm),
          Wrap(
            spacing: AppLayout.spaceSm,
            runSpacing: AppLayout.spaceXs,
            children: [
              AuroraBadge(label: '$groupCount categorias'),
              AuroraBadge(label: '$columnCount itens'),
            ],
          ),
        ],
      ),
    );
  }
}

// Acoes disponiveis no card da categoria.
enum _GroupAction { addColumn, editGroup, removeGroup }

// Acoes de adicionar categoria/subcategoria em icones soltos.
class _ActionIcons extends StatelessWidget {
  final VoidCallback onAddCategory;
  final VoidCallback onAddSubcategory;
  final bool canAddSubcategory;

  const _ActionIcons({
    required this.onAddCategory,
    required this.onAddSubcategory,
    required this.canAddSubcategory,
  });

  @override
  // Monta os icones de acao sem borda.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Tooltip(
          message: 'Nova categoria',
          child: IconButton(
            onPressed: onAddCategory,
            icon: const Icon(Icons.folder_open),
            color: tokens.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: AppLayout.spaceSm),
        Tooltip(
          message: 'Nova subcategoria',
          child: IconButton(
            onPressed: canAddSubcategory ? onAddSubcategory : null,
            icon: const Icon(Icons.add_circle_outline),
            color: tokens.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

// Card de categoria com itens de gasto e acoes.
class _GroupCard extends StatelessWidget {
  final ExpenseGroup group;
  final String totalLabel;
  final VoidCallback onEditGroup;
  final VoidCallback onRemoveGroup;
  final VoidCallback onAddColumn;
  final void Function(ExpenseColumn column) onEditColumn;
  final void Function(ExpenseColumn column) onRemoveColumn;
  final void Function(int oldIndex, int newIndex) onReorderColumns;
  final Widget dragHandle;
  final Widget Function(ExpenseColumn column, int index) buildCell;

  const _GroupCard({
    required this.group,
    required this.totalLabel,
    required this.onEditGroup,
    required this.onRemoveGroup,
    required this.onAddColumn,
    required this.onEditColumn,
    required this.onRemoveColumn,
    required this.onReorderColumns,
    required this.dragHandle,
    required this.buildCell,
  });

  @override
  // Monta o card da categoria.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.spaceMd,
        AppLayout.spaceXs,
        AppLayout.spaceMd,
        AppLayout.spaceMd,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.surfaceAlt, tokens.surface],
        ),
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        dragHandle,
                        const SizedBox(width: AppLayout.spaceSm),
                        Expanded(
                          child: Text(
                            group.title,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppLayout.spaceSm),
                        Text(
                          totalLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        PopupMenuButton<_GroupAction>(
                          onSelected: (action) {
                            switch (action) {
                              case _GroupAction.addColumn:
                                onAddColumn();
                              case _GroupAction.editGroup:
                                onEditGroup();
                              case _GroupAction.removeGroup:
                                onRemoveGroup();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          iconSize: 20,
                          icon: Icon(
                            Icons.more_vert,
                            color: tokens.textSecondary,
                          ),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _GroupAction.addColumn,
                              child: Text('Adicionar subcategoria'),
                            ),
                            PopupMenuItem(
                              value: _GroupAction.editGroup,
                              child: Text('Editar categoria'),
                            ),
                            PopupMenuItem(
                              value: _GroupAction.removeGroup,
                              child: Text('Remover categoria'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dragHandle,
                  const SizedBox(width: AppLayout.spaceSm),
                  Expanded(
                    child: Text(
                      group.title,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    totalLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppLayout.spaceSm),
                  IconButton(
                    onPressed: onAddColumn,
                    icon: const Icon(Icons.add),
                    tooltip: 'Adicionar subcategoria',
                    color: tokens.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onEditGroup,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar categoria',
                    color: tokens.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onRemoveGroup,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover categoria',
                    color: tokens.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              );
            },
          ),
          if (group.columns.isEmpty)
            Text(
              'Sem itens de gasto. Clique em adicionar para incluir.',
              style: TextStyle(color: tokens.textSecondary),
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

                if (crossAxisCount == 1) {
                  return ReorderableListView.builder(
                    // Reordena subcategorias no layout de uma coluna.
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    // Remove o fundo escuro do item arrastado.
                    proxyDecorator: (child, index, animation) {
                      return Builder(
                        builder: (context) {
                          final tokens = AppThemeTokens.of(context);
                          return Material(
                            color: Colors.transparent,
                            elevation: 4,
                            shadowColor: tokens.shadow,
                            borderRadius: BorderRadius.circular(
                              AppLayout.radiusMd,
                            ),
                            child: child,
                          );
                        },
                      );
                    },
                    itemCount: group.columns.length,
                    onReorder: onReorderColumns,
                    itemBuilder: (context, index) {
                      final column = group.columns[index];
                      return Padding(
                        key: ValueKey(column.id),
                        padding: const EdgeInsets.only(
                          bottom: AppLayout.spaceXs,
                        ),
                        child: Stack(
                          children: [
                            buildCell(column, index),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_indicator,
                                      size: 18,
                                    ),
                                  ),
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
                        ),
                      );
                    },
                  );
                }

                return GridView.builder(
                  // Remove padding interno para evitar vao entre titulo e itens.
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.columns.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppLayout.spaceXs,
                    mainAxisSpacing: AppLayout.spaceXs,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final column = group.columns[index];
                    return Stack(
                      children: [
                        buildCell(column, index),
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

// Tile com resumo de item detalhado.
class _ColumnSummaryTile extends StatelessWidget {
  final String title;
  final String totalLabel;
  final String countLabel;
  final VoidCallback onTap;

  const _ColumnSummaryTile({
    required this.title,
    required this.totalLabel,
    required this.countLabel,
    required this.onTap,
  });

  @override
  // Monta o tile de resumo do item.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.radiusMd),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.spaceMd,
          AppLayout.spaceMd,
          AppLayout.spaceMd,
          AppLayout.spaceMd,
        ),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(AppLayout.radiusMd),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, size: 14, color: tokens.textMuted),
                const SizedBox(width: AppLayout.spaceSm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spaceSm),
            Text(
              totalLabel,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppLayout.spaceXs),
            Row(
              children: [
                Text(
                  countLabel,
                  style: TextStyle(color: tokens.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tile de item fixo editavel.
class _ColumnValueTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onApply;

  const _ColumnValueTile({
    required this.title,
    required this.controller,
    required this.onChanged,
    required this.onApply,
  });

  @override
  // Monta o tile de valor fixo.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxHeight < 100;
        return Container(
          padding: EdgeInsets.fromLTRB(
            AppLayout.spaceMd,
            isTight ? AppLayout.spaceSm : AppLayout.spaceMd,
            AppLayout.spaceMd,
            isTight ? AppLayout.spaceXs : AppLayout.spaceSm,
          ),
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(AppLayout.radiusMd),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.push_pin, size: 12, color: tokens.textMuted),
                  const SizedBox(width: AppLayout.spaceSm),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: isTight ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.spaceSm),
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    onApply(controller.text);
                  }
                },
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    CurrencyInputFormatter(
                      locale: settings.currencyLocale,
                      symbol: settings.currencySymbol,
                    ),
                  ],
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: isTight ? 13 : 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: '0,00',
                    hintStyle: TextStyle(color: tokens.textMuted),
                  ),
                  onChanged: (value) {
                    onChanged(value);
                    onApply(value);
                  },
                  onEditingComplete: () => onApply(controller.text),
                  onSubmitted: (_) => onApply(controller.text),
                ),
              ),
              // Indicador removido para evitar overflow em tiles compactos.
            ],
          ),
        );
      },
    );
  }
}

// Rodape com total do mes.
class _TotalFooter extends StatelessWidget {
  final String label;

  const _TotalFooter({required this.label});

  @override
  // Monta o rodape de total.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceLg,
        vertical: AppLayout.spaceMd,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceStrong,
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: tokens.borderStrong),
      ),
      child: Row(
        children: [
          Text('Total do mes', style: TextStyle(color: tokens.textSecondary)),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Botao compacto para acoes do item.
class _TinyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TinyIconButton({required this.icon, required this.onTap});

  @override
  // Monta o botao compacto.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.spaceXs),
        child: Icon(icon, size: AppLayout.iconSm, color: tokens.textSecondary),
      ),
    );
  }
}
