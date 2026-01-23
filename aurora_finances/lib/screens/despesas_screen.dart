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

// Tela de despesas com categorias e subcategorias.
class ExpensesScreen extends StatefulWidget {
  final ExpensesStore expensesStore;
  final CategoriesStore entryCategoriesStore;

  const ExpensesScreen({
    super.key,
    required this.expensesStore,
    required this.entryCategoriesStore,
  });

  @override
  // Cria o estado da tela de despesas.
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

// Estado da tela de despesas com navegacao de meses.
class _ExpensesScreenState extends State<ExpensesScreen> {
  static final DateTime _startMonth = DateTime(2026, 1, 1);

  final Map<String, TextEditingController> _fixedValueControllers = {};
  late DateTime _selectedMonth;
  late PageController _monthPagerController;
  late int _currentMonthIndex;

  @override
  // Inicializa stores e prepara a navegacao entre meses.
  void initState() {
    super.initState();
    if (!widget.expensesStore.isLoaded) {
      widget.expensesStore.load();
    }
    if (!widget.entryCategoriesStore.isLoaded) {
      widget.entryCategoriesStore.load();
    }
    _selectedMonth = _resolveInitialMonth();
    _currentMonthIndex = _monthsBetween(_startMonth, _selectedMonth);
    _monthPagerController = PageController(initialPage: _currentMonthIndex);
  }

  @override
  // Libera recursos locais usados na tela.
  void dispose() {
    for (final controller in _fixedValueControllers.values) {
      controller.dispose();
    }
    _monthPagerController.dispose();
    super.dispose();
  }

  @override
  // Monta a tela principal de despesas.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final monthFormatter = settings.monthYearFormatter();
    final moneyFormatter = settings.currencyFormatter();

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [
          IconButton(
            onPressed: _openEntryCategories,
            icon: const Icon(Icons.category),
            tooltip: 'Categorias',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.expensesStore,
        builder: (context, _) {
          if (!widget.expensesStore.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildLoadedContent(
            monthFormatter: monthFormatter,
            moneyFormatter: moneyFormatter,
          );
        },
      ),
    );
  }

  // Monta o conteudo quando os dados ja estao carregados.
  Widget _buildLoadedContent({
    required DateFormat monthFormatter,
    required NumberFormat moneyFormatter,
  }) {
    final summary = _buildMonthSummary();
    final categories = widget.expensesStore.categories;

    return Padding(
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthSelector(
            controller: _monthPagerController,
            formatter: monthFormatter,
            startMonth: _startMonth,
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
            totalLabel: moneyFormatter.format(summary.monthTotal),
            categoryCount: summary.categoryCount,
            subcategoryCount: summary.subcategoryCount,
          ),
          _ActionIcons(
            onAddCategory: _addCategory,
            onAddSubcategory: _addSubcategory,
            canAddSubcategory: categories.isNotEmpty,
          ),
          const SizedBox(height: AppLayout.spaceSm),
          Expanded(
            child: categories.isEmpty
                ? _EmptyState(onAddCategory: _addCategory)
                : _buildCategoryList(
                    categories: categories,
                    moneyFormatter: moneyFormatter,
                  ),
          ),
          const SizedBox(height: AppLayout.spaceMd),
          _TotalFooter(label: moneyFormatter.format(summary.monthTotal)),
        ],
      ),
    );
  }

  // Consolida totais e contagens do mes para simplificar o layout.
  _MonthSummary _buildMonthSummary() {
    final categories = widget.expensesStore.categories;
    final subcategoryCount = categories.fold<int>(
      0,
      (sum, category) => sum + category.subcategories.length,
    );
    return _MonthSummary(
      monthTotal: widget.expensesStore.totalForMonth(_selectedMonth),
      categoryCount: categories.length,
      subcategoryCount: subcategoryCount,
    );
  }

  // Monta a lista reordenavel de categorias.
  Widget _buildCategoryList({
    required List<ExpenseCategory> categories,
    required NumberFormat moneyFormatter,
  }) {
    return ReorderableListView.builder(
      padding: EdgeInsets.zero,
      primary: false,
      buildDefaultDragHandles: false,
      // Mantem o item arrastado sem fundo escuro, com sombra sutil.
      proxyDecorator: (child, index, animation) {
        return _buildDragProxy(child);
      },
      itemCount: categories.length,
      onReorder: widget.expensesStore.reorderCategories,
      itemBuilder: (context, index) {
        final category = categories[index];
        final total = widget.expensesStore.totalForCategory(
          _selectedMonth,
          category,
        );

        return Padding(
          key: ValueKey(category.id),
          padding: const EdgeInsets.only(bottom: AppLayout.spaceMd),
          child: _CategoryCard(
            category: category,
            totalLabel: moneyFormatter.format(total),
            onEditCategory: () => _editCategory(category),
            onRemoveCategory: () => _removeCategory(category),
            onAddSubcategory: () => _addSubcategoryForCategory(category),
            onEditSubcategory: (subcategory) =>
                _editSubcategory(category, subcategory),
            onRemoveSubcategory: (subcategory) =>
                _removeSubcategory(category, subcategory),
            onReorderSubcategories: (oldIndex, newIndex) =>
                widget.expensesStore.reorderSubcategories(
                  category,
                  oldIndex,
                  newIndex,
                ),
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            buildTile: (subcategory) => _buildSubcategoryTile(
              category: category,
              subcategory: subcategory,
              moneyFormatter: moneyFormatter,
            ),
          ),
        );
      },
    );
  }

  // Desenha o proxy visual do item arrastado.
  Widget _buildDragProxy(Widget child) {
    final tokens = AppThemeTokens.of(context);
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shadowColor: tokens.shadow,
      borderRadius: BorderRadius.circular(AppLayout.radiusLg),
      child: child,
    );
  }

  // Monta o tile conforme o tipo de subcategoria.
  Widget _buildSubcategoryTile({
    required ExpenseCategory category,
    required ExpenseSubcategory subcategory,
    required NumberFormat moneyFormatter,
  }) {
    if (!subcategory.requiresEntries) {
      final controller = _fixedValueControllerFor(
        _selectedMonth,
        subcategory,
        moneyFormatter,
      );
      final currentValue = widget.expensesStore.valueForSubcategory(
        _selectedMonth,
        subcategory,
      );
      final isPositive = currentValue > 0;
      return _SubcategoryFixedValueTile(
        title: subcategory.title,
        controller: controller,
        isPositive: isPositive,
        onChanged: (value) => _updateFixedValueForMonth(
          _selectedMonth,
          subcategory,
          value,
          isPositive,
        ),
        onApply: (value) => _applyFixedValueFromMonth(
          _selectedMonth,
          subcategory,
          value,
          isPositive,
        ),
        onSignChanged: (nextSign) => _updateFixedValueSign(
          _selectedMonth,
          subcategory,
          nextSign,
          controller,
        ),
      );
    }

    final total = widget.expensesStore.totalForSubcategory(
      _selectedMonth,
      subcategory,
    );
    final count = widget.expensesStore.countForSubcategory(
      _selectedMonth,
      subcategory,
    );
    return _SubcategorySummaryTile(
      title: subcategory.title,
      totalLabel: moneyFormatter.format(total),
      countLabel: '$count itens',
      onTap: () => _openSubcategoryEntries(category, subcategory),
    );
  }

  // Define o mes inicial exibido respeitando o inicio do app.
  DateTime _resolveInitialMonth() {
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, 1);
    if (normalized.isBefore(_startMonth)) {
      return _startMonth;
    }
    return normalized;
  }

  // Calcula o deslocamento em meses.
  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  // Converte indice em data do mes.
  DateTime _monthFromIndex(int index) {
    return DateTime(_startMonth.year, _startMonth.month + index, 1);
  }

  // Indica se e possivel voltar um mes.
  bool _canGoPrevious() => _currentMonthIndex > 0;

  // Navega para o mes anterior com animacao.
  void _previousMonth() {
    if (!_canGoPrevious()) return;
    _monthPagerController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // Navega para o proximo mes com animacao.
  void _nextMonth() {
    _monthPagerController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // Atualiza o mes selecionado e reseta inputs locais.
  void _setSelectedMonth(int index) {
    _currentMonthIndex = index;
    _selectedMonth = _monthFromIndex(index);
    _resetFixedValueControllers();
  }

  // Reseta os controllers de valores fixos do mes atual.
  void _resetFixedValueControllers() {
    for (final controller in _fixedValueControllers.values) {
      controller.dispose();
    }
    _fixedValueControllers.clear();
  }

  // Abre a tela de lancamentos da subcategoria.
  void _openSubcategoryEntries(
    ExpenseCategory category,
    ExpenseSubcategory subcategory,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseSubcategoryEntriesScreen(
          expensesStore: widget.expensesStore,
          entryCategoriesStore: widget.entryCategoriesStore,
          category: category,
          subcategory: subcategory,
          initialMonth: _selectedMonth,
        ),
      ),
    );
  }

  // Abre a tela de categorias globais de lancamentos.
  void _openEntryCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoriesScreen(store: widget.entryCategoriesStore),
      ),
    );
  }

  // Retorna controller para subcategoria fixa por mes.
  TextEditingController _fixedValueControllerFor(
    DateTime month,
    ExpenseSubcategory subcategory,
    NumberFormat formatter,
  ) {
    final key = '${monthKey(month)}|${subcategory.id}';
    return _fixedValueControllers.putIfAbsent(key, () {
      final controller = TextEditingController();
      final value =
          widget.expensesStore.valueForSubcategory(month, subcategory);
      if (value != 0) {
        controller.text = formatter.format(value.abs());
      }
      return controller;
    });
  }

  // Aplica o sinal correto a um valor numerico.
  double _signedAmount(double value, bool isPositive) {
    return isPositive ? value.abs() : -value.abs();
  }

  // Aplica valor fixo a partir do mes selecionado.
  void _applyFixedValueFromMonth(
    DateTime month,
    ExpenseSubcategory subcategory,
    String value,
    bool isPositive,
  ) {
    final parsed = parseCurrencyToDouble(value);
    final signed = _signedAmount(parsed, isPositive);
    final settings = AppSettingsScope.of(context);
    final formatter = settings.currencyFormatter();
    final end = DateTime(2030, 12, 1);
    widget.expensesStore.setFixedValueFromMonth(
      month,
      end,
      subcategory,
      signed,
    );

    _fixedValueControllers.forEach((key, controller) {
      final parts = key.split('|');
      if (parts.length != 2 || parts[1] != subcategory.id) {
        return;
      }
      final parsedMonth = parseMonthKey(parts[0]);
      if (parsedMonth == null || parsedMonth.isBefore(month)) {
        return;
      }
      controller.text = signed == 0 ? '' : formatter.format(signed.abs());
    });
  }

  // Atualiza o valor fixo da subcategoria no mes atual.
  void _updateFixedValueForMonth(
    DateTime month,
    ExpenseSubcategory subcategory,
    String value,
    bool isPositive,
  ) {
    final parsed = parseCurrencyToDouble(value);
    final signed = _signedAmount(parsed, isPositive);
    widget.expensesStore.setValueForSubcategory(month, subcategory, signed);
  }

  // Atualiza o sinal do valor fixo e sincroniza o controller.
  void _updateFixedValueSign(
    DateTime month,
    ExpenseSubcategory subcategory,
    bool isPositive,
    TextEditingController controller,
  ) {
    final parsed = parseCurrencyToDouble(controller.text);
    final signed = _signedAmount(parsed, isPositive);
    widget.expensesStore.setValueForSubcategory(month, subcategory, signed);
    final settings = AppSettingsScope.of(context);
    final formatter = settings.currencyFormatter();
    controller.text = signed == 0 ? '' : formatter.format(signed.abs());
  }

  // Cria uma nova categoria de despesas.
  Future<void> _addCategory() async {
    final title = await _promptForText(
      title: 'Nova categoria',
      label: 'Nome da categoria',
    );
    if (title == null || title.trim().isEmpty) return;
    widget.expensesStore.addCategory(title.trim());
    _showSnack('Categoria criada');
  }

  // Edita o nome da categoria.
  Future<void> _editCategory(ExpenseCategory category) async {
    final title = await _promptForText(
      title: 'Editar categoria',
      label: 'Nome da categoria',
      initialValue: category.title,
    );
    if (title == null || title.trim().isEmpty) return;
    widget.expensesStore.updateCategory(category, title.trim());
  }

  // Remove uma categoria e seus itens de gasto.
  void _removeCategory(ExpenseCategory category) {
    widget.expensesStore.removeCategory(category);
  }

  // Cria uma nova subcategoria em qualquer categoria.
  Future<void> _addSubcategory() async {
    final result = await _promptForSubcategory();
    if (result == null) return;
    widget.expensesStore.addSubcategory(
      result.category,
      result.title,
      requiresEntries: result.requiresEntries,
    );
    _showSnack('Subcategoria adicionada');
  }

  // Cria uma nova subcategoria para uma categoria especifica.
  Future<void> _addSubcategoryForCategory(ExpenseCategory category) async {
    final result = await _promptForSubcategory(category: category);
    if (result == null) return;
    widget.expensesStore.addSubcategory(
      category,
      result.title,
      requiresEntries: result.requiresEntries,
    );
    _showSnack('Subcategoria adicionada');
  }

  // Edita o titulo da subcategoria.
  Future<void> _editSubcategory(
    ExpenseCategory category,
    ExpenseSubcategory subcategory,
  ) async {
    final title = await _promptForText(
      title: 'Editar subcategoria',
      label: 'Nome da subcategoria',
      initialValue: subcategory.title,
    );
    if (title == null || title.trim().isEmpty) return;
    widget.expensesStore.updateSubcategory(category, subcategory, title.trim());
  }

  // Remove uma subcategoria de uma categoria.
  Future<void> _removeSubcategory(
    ExpenseCategory category,
    ExpenseSubcategory subcategory,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover subcategoria'),
          content: Text(
            'Remover "${subcategory.title}" e todos os lancamentos associados?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    widget.expensesStore.removeSubcategory(category, subcategory);
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
  Future<_SubcategoryInput?> _promptForSubcategory({
    ExpenseCategory? category,
  }) async {
    final availableCategories = widget.expensesStore.categories;
    if (availableCategories.isEmpty) {
      return null;
    }
    final controller = TextEditingController();
    ExpenseCategory selectedCategory = category ?? availableCategories.first;
    bool requiresEntries = false;

    return showDialog<_SubcategoryInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova subcategoria'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.folder_open),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppLayout.spaceSm,
                      ),
                    ),
                    items: availableCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedCategory = value);
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
                    title: const Text('Registrar lancamentos detalhados'),
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
                      _SubcategoryInput(
                        selectedCategory,
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

// Modelo interno para agrupar dados de resumo do mes.
class _MonthSummary {
  final double monthTotal;
  final int categoryCount;
  final int subcategoryCount;

  const _MonthSummary({
    required this.monthTotal,
    required this.categoryCount,
    required this.subcategoryCount,
  });
}

// Modelo interno para cadastrar uma nova subcategoria.
class _SubcategoryInput {
  _SubcategoryInput(this.category, this.title, {required this.requiresEntries});

  final ExpenseCategory category;
  final String title;
  final bool requiresEntries;
}

// Seletor de mes com paginação.
class _MonthSelector extends StatelessWidget {
  final PageController controller;
  final DateFormat formatter;
  final DateTime startMonth;
  final void Function(int index) onChanged;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.controller,
    required this.formatter,
    required this.startMonth,
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
                  final month = DateTime(
                    startMonth.year,
                    startMonth.month + index,
                    1,
                  );
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
  final VoidCallback onAddCategory;

  const _EmptyState({required this.onAddCategory});

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
              onPressed: onAddCategory,
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
  final int categoryCount;
  final int subcategoryCount;

  const _SummaryCard({
    required this.totalLabel,
    required this.categoryCount,
    required this.subcategoryCount,
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
              AuroraBadge(label: '$categoryCount categorias'),
              AuroraBadge(label: '$subcategoryCount itens'),
            ],
          ),
        ],
      ),
    );
  }
}

// Acoes disponiveis no card da categoria.
enum _CategoryAction { addSubcategory, editCategory, removeCategory }

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
class _CategoryCard extends StatelessWidget {
  final ExpenseCategory category;
  final String totalLabel;
  final VoidCallback onEditCategory;
  final VoidCallback onRemoveCategory;
  final VoidCallback onAddSubcategory;
  final void Function(ExpenseSubcategory subcategory) onEditSubcategory;
  final void Function(ExpenseSubcategory subcategory) onRemoveSubcategory;
  final void Function(int oldIndex, int newIndex) onReorderSubcategories;
  final Widget dragHandle;
  final Widget Function(ExpenseSubcategory subcategory) buildTile;

  const _CategoryCard({
    required this.category,
    required this.totalLabel,
    required this.onEditCategory,
    required this.onRemoveCategory,
    required this.onAddSubcategory,
    required this.onEditSubcategory,
    required this.onRemoveSubcategory,
    required this.onReorderSubcategories,
    required this.dragHandle,
    required this.buildTile,
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
                            category.title,
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
                        PopupMenuButton<_CategoryAction>(
                          onSelected: (action) {
                            switch (action) {
                              case _CategoryAction.addSubcategory:
                                onAddSubcategory();
                                break;
                              case _CategoryAction.editCategory:
                                onEditCategory();
                                break;
                              case _CategoryAction.removeCategory:
                                onRemoveCategory();
                                break;
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          color: tokens.surface,
                          iconSize: 20,
                          icon: Icon(
                            Icons.more_vert,
                            color: tokens.textSecondary,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _CategoryAction.addSubcategory,
                              child: Text(
                                'Adicionar subcategoria',
                                style: TextStyle(color: tokens.textPrimary),
                              ),
                            ),
                            PopupMenuItem(
                              value: _CategoryAction.editCategory,
                              child: Text(
                                'Editar categoria',
                                style: TextStyle(color: tokens.textPrimary),
                              ),
                            ),
                            PopupMenuItem(
                              value: _CategoryAction.removeCategory,
                              child: Text(
                                'Remover categoria',
                                style: TextStyle(color: tokens.textPrimary),
                              ),
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
                      category.title,
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
                    onPressed: onAddSubcategory,
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
                    onPressed: onEditCategory,
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
                    onPressed: onRemoveCategory,
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
          if (category.subcategories.isEmpty)
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
                    itemCount: category.subcategories.length,
                    onReorder: onReorderSubcategories,
                    itemBuilder: (context, index) {
                      final subcategory = category.subcategories[index];
                      return Padding(
                        key: ValueKey(subcategory.id),
                        padding: const EdgeInsets.only(
                          bottom: AppLayout.spaceXs,
                        ),
                        child: Stack(
                          children: [
                            buildTile(subcategory),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Row(
                                children: [
                                  _TinyIconButton(
                                    icon: Icons.edit,
                                    onTap: () => onEditSubcategory(subcategory),
                                  ),
                                  _TinyIconButton(
                                    icon: Icons.close,
                                    onTap: () =>
                                        onRemoveSubcategory(subcategory),
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
                  itemCount: category.subcategories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppLayout.spaceXs,
                    mainAxisSpacing: AppLayout.spaceXs,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final subcategory = category.subcategories[index];
                    return Stack(
                      children: [
                        buildTile(subcategory),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Row(
                            children: [
                              _TinyIconButton(
                                icon: Icons.edit,
                                onTap: () => onEditSubcategory(subcategory),
                              ),
                              _TinyIconButton(
                                icon: Icons.close,
                                onTap: () => onRemoveSubcategory(subcategory),
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

// Tile com resumo da subcategoria detalhada.
class _SubcategorySummaryTile extends StatelessWidget {
  final String title;
  final String totalLabel;
  final String countLabel;
  final VoidCallback onTap;

  const _SubcategorySummaryTile({
    required this.title,
    required this.totalLabel,
    required this.countLabel,
    required this.onTap,
  });

  @override
  // Monta o tile de resumo da subcategoria.
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

// Tile de subcategoria fixa editavel.
class _SubcategoryFixedValueTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isPositive;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onApply;
  final ValueChanged<bool> onSignChanged;

  const _SubcategoryFixedValueTile({
    required this.title,
    required this.controller,
    required this.isPositive,
    required this.onChanged,
    required this.onApply,
    required this.onSignChanged,
  });

  @override
  // Monta o tile de valor fixo.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxHeight < 100;
        final amountColor = isPositive ? tokens.success : tokens.danger;
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
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => onSignChanged(!isPositive),
                      icon: Icon(isPositive ? Icons.add : Icons.remove),
                      color: amountColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
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
                          color: amountColor,
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
                  ],
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
