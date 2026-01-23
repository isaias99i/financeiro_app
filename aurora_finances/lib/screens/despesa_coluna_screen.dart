import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../data/categories_store.dart';
import '../models/despesas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_badge.dart';
import '../widgets/aurora_scaffold.dart';
import '../screens/categorias_screen.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_tokens.dart';

// Tela de lancamentos detalhados de uma subcategoria de despesas.
class ExpenseSubcategoryEntriesScreen extends StatefulWidget {
  final ExpensesStore expensesStore;
  final CategoriesStore entryCategoriesStore;
  final ExpenseCategory category;
  final ExpenseSubcategory subcategory;
  final DateTime initialMonth;

  const ExpenseSubcategoryEntriesScreen({
    super.key,
    required this.expensesStore,
    required this.entryCategoriesStore,
    required this.category,
    required this.subcategory,
    required this.initialMonth,
  });

  @override
  // Cria o estado da tela de subcategoria.
  State<ExpenseSubcategoryEntriesScreen> createState() =>
      _ExpenseSubcategoryEntriesScreenState();
}

// Estado da tela de subcategoria com filtro por mes.
class _ExpenseSubcategoryEntriesScreenState
    extends State<ExpenseSubcategoryEntriesScreen> {
  late DateTime _selectedMonth;

  @override
  // Inicializa o mes selecionado e garante categorias carregadas.
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
      1,
    );
    if (!widget.entryCategoriesStore.isLoaded) {
      widget.entryCategoriesStore.load();
    }
  }

  @override
  // Monta a UI com resumo e lista de lancamentos.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    final dateFormatter = settings.dateFormatter();
    final monthFormatter = settings.monthYearFormatter();
    final moneyFormatter = settings.currencyFormatter();

    return AuroraScaffold(
      appBar: AppBar(
        title: Text(widget.subcategory.title),
        actions: [
          IconButton(
            onPressed: () => _pickMonth(context),
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Alterar mes',
          ),
          IconButton(
            onPressed: _confirmClearMonthEntries,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar movimentacoes do mes',
          ),
          IconButton(
            onPressed: _openCategories,
            icon: const Icon(Icons.category),
            tooltip: 'Categorias',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: widget.expensesStore,
        builder: (context, _) {
          final entries = _entriesForSelectedMonth();
          final total = _totalForEntries(entries);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSummary(
                  monthLabel: monthFormatter.format(_selectedMonth),
                  totalLabel: moneyFormatter.format(total),
                  countLabel: '${entries.length} itens',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildEntriesList(
                    entries: entries,
                    dateFormatter: dateFormatter,
                    moneyFormatter: moneyFormatter,
                    tokens: tokens,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Filtra e ordena entradas do mes selecionado.
  List<ExpenseEntry> _entriesForSelectedMonth() {
    final entries =
        widget.expensesStore.entriesForSubcategory(widget.subcategory);
    final filtered = entries
        .where((entry) => isSameMonth(entry.date, _selectedMonth))
        .toList();
    filtered.sort((a, b) {
      final aDate = a.purchaseDate ?? a.date;
      final bDate = b.purchaseDate ?? b.date;
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  // Soma o total de uma lista de lancamentos.
  double _totalForEntries(List<ExpenseEntry> entries) {
    return entries.fold<double>(0.0, (sum, entry) => sum + entry.amount);
  }

  // Monta a lista de lancamentos ou estado vazio.
  Widget _buildEntriesList({
    required List<ExpenseEntry> entries,
    required DateFormat dateFormatter,
    required NumberFormat moneyFormatter,
    required AppThemeTokens tokens,
  }) {
    if (entries.isEmpty) {
      return _EmptyEntries(onAdd: _showAddDialog);
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          color: tokens.surfaceAlt,
          child: ListTile(
            onTap: () => _showEditDialog(entry),
            leading: Icon(Icons.receipt_long, color: tokens.textSecondary),
            title: Text(
              entry.category.isEmpty ? 'Sem categoria' : entry.category,
              style: TextStyle(color: tokens.textPrimary),
            ),
            subtitle: Text(
              _subtitleForEntry(entry, dateFormatter),
              style: TextStyle(color: tokens.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  moneyFormatter.format(entry.amount),
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _removeEntry(entry),
                  icon: Icon(Icons.delete_outline, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Abre o seletor de mes.
  Future<void> _pickMonth(BuildContext context) async {
    final picked = await _pickDate(
      context: context,
      initialDate: _selectedMonth,
      helpText: 'Selecionar mes',
    );
    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
  }

  // Confirma a limpeza das movimentacoes do mes selecionado.
  Future<void> _confirmClearMonthEntries() async {
    final settings = AppSettingsScope.of(context);
    final monthLabel = settings.monthYearFormatter().format(_selectedMonth);
    final entries = _entriesForSelectedMonth();
    if (entries.isEmpty) {
      _showSnack('Nao ha movimentacoes neste mes.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar movimentacoes'),
          content: Text('Remover todas as movimentacoes de $monthLabel?'),
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
    _clearMonthEntries(entries);
  }

  // Remove todas as movimentacoes do mes atual.
  void _clearMonthEntries(List<ExpenseEntry> entries) {
    final ids = entries.map((entry) => entry.id).toList();
    for (final id in ids) {
      widget.expensesStore.removeEntry(id);
    }
    _showSnack('Movimentacoes removidas.');
  }

  // Abre dialogo para adicionar gasto.
  Future<void> _showAddDialog() async {
    await _showEntryDialog();
  }

  // Abre dialogo para editar gasto.
  Future<void> _showEditDialog(ExpenseEntry entry) async {
    await _showEntryDialog(entry: entry);
  }

  // Dialogo principal de adicionar/editar gasto.
  Future<void> _showEntryDialog({ExpenseEntry? entry}) async {
    final settings = AppSettingsScope.of(context);
    final reasonController = TextEditingController(text: entry?.reason ?? '');
    final initialAmount = entry?.amount ?? 0.0;
    final amountController = TextEditingController(
      text: entry != null ? initialAmount.abs().toStringAsFixed(2) : '',
    );
    DateTime selectedDate = entry?.date ?? _selectedMonth;
    bool isInstallment = entry?.isInstallment ?? false;
    bool isPositive = entry != null ? initialAmount >= 0 : false;
    final installmentCountController = TextEditingController(
      text: entry?.installmentCount?.toString() ?? '1',
    );
    final installmentIndexController = TextEditingController(
      text: entry?.installmentIndex?.toString() ?? '1',
    );
    DateTime purchaseDate = entry?.purchaseDate ?? _selectedMonth;
    final categoryList = widget.entryCategoriesStore.categories.toList();
    final entryCategory = entry?.category.trim() ?? '';
    if (entryCategory.isNotEmpty && !categoryList.contains(entryCategory)) {
      categoryList.insert(0, entryCategory);
    }
    String? selectedCategory = categoryList.isNotEmpty
        ? (entryCategory.isNotEmpty ? entryCategory : categoryList.first)
        : null;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final tokens = AppThemeTokens.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(entry == null ? 'Adicionar gasto' : 'Editar gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (categoryList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nenhuma categoria cadastrada.',
                              style: TextStyle(color: tokens.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _openCategories();
                              },
                              icon: const Icon(Icons.category),
                              label: const Text('Gerenciar categorias'),
                            ),
                          ],
                        ),
                      ),
                    if (categoryList.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        items: categoryList
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedCategory = value);
                        },
                      ),
                    if (categoryList.isNotEmpty) const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      enableSuggestions: true,
                      autocorrect: true,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        CurrencyInputFormatter(
                          locale: settings.currencyLocale,
                          symbol: settings.currencySymbol,
                        ),
                      ],
                      decoration: const InputDecoration(labelText: 'Valor'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Despesa (-)'),
                          selected: !isPositive,
                          onSelected: (_) {
                            setState(() => isPositive = false);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Credito (+)'),
                          selected: isPositive,
                          onSelected: (_) {
                            setState(() => isPositive = true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Compra parcelada'),
                      subtitle: const Text('Criar parcelas nos meses seguintes'),
                      value: isInstallment,
                      onChanged: (value) {
                        setState(() => isInstallment = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (isInstallment)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: installmentCountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Parcelas'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: installmentIndexController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Parcela atual'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Data da compra: ${settings.dateFormatter().format(purchaseDate)}',
                              ),
                              onPressed: () async {
                                final picked = await _pickDate(
                                  context: context,
                                  initialDate: purchaseDate,
                                );
                                if (picked != null) {
                                  setState(() => purchaseDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    if (!isInstallment)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            'Data da compra: ${settings.dateFormatter().format(purchaseDate)}',
                          ),
                          onPressed: () async {
                            final picked = await _pickDate(
                              context: context,
                              initialDate: purchaseDate,
                            );
                            if (picked != null) {
                              setState(() => purchaseDate = picked);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (categoryList.isNotEmpty && selectedCategory == null) {
                      return;
                    }
                    final amount = parseCurrencyToDouble(amountController.text);
                    if (amount <= 0) {
                      return;
                    }
                    final signedAmount = isPositive ? amount : -amount;

                    if (isInstallment) {
                      final count = int.tryParse(installmentCountController.text) ?? 1;
                      final index = int.tryParse(installmentIndexController.text) ?? 1;
                      if (count <= 0 || index <= 0 || index > count) {
                        return;
                      }
                      _saveInstallments(
                        entry: entry,
                        count: count,
                        index: index,
                        purchaseDate: purchaseDate,
                        amount: signedAmount,
                        category: selectedCategory ?? '',
                        reason: reasonController.text.trim(),
                      );
                    } else {
                      final nextPurchaseDate = purchaseDate;
                      final clearInstallments = entry?.isInstallment == true;
                      if (entry == null) {
                        widget.expensesStore.addEntry(
                          ExpenseEntry(
                            id: _nextEntryId(),
                            subcategoryId: widget.subcategory.id,
                            date: selectedDate,
                            category: selectedCategory ?? '',
                            reason: reasonController.text.trim(),
                            amount: signedAmount,
                            purchaseDate: nextPurchaseDate,
                          ),
                        );
                      } else {
                        widget.expensesStore.updateEntry(
                          entry.id,
                          entry.copyWith(
                            date: selectedDate,
                            category: selectedCategory ?? '',
                            reason: reasonController.text.trim(),
                            amount: signedAmount,
                            installmentCount:
                                clearInstallments ? null : entry.installmentCount,
                            installmentIndex:
                                clearInstallments ? null : entry.installmentIndex,
                            purchaseDate: nextPurchaseDate,
                          ),
                        );
                      }
                    }
                    Navigator.pop(context);
                    _showSnack('Gasto salvo');
                  },
                  child: Text(entry == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Salva parcelas criando entradas futuras.
  void _saveInstallments({
    required ExpenseEntry? entry,
    required int count,
    required int index,
    required DateTime purchaseDate,
    required double amount,
    required String category,
    required String reason,
  }) {
    if (entry != null) {
      widget.expensesStore.updateEntry(
        entry.id,
        entry.copyWith(
          date: entry.date,
          category: category,
          reason: reason,
          amount: amount,
          installmentCount: count,
          installmentIndex: index,
          purchaseDate: purchaseDate,
        ),
      );
      return;
    }

    for (var i = index; i <= count; i++) {
      widget.expensesStore.addEntry(
        ExpenseEntry(
          id: _nextEntryId(),
          subcategoryId: widget.subcategory.id,
          date: _installmentDate(purchaseDate, i),
          category: category,
          reason: reason,
          amount: amount,
          installmentCount: count,
          installmentIndex: i,
          purchaseDate: purchaseDate,
        ),
      );
    }
  }

  // Calcula a data da parcela com ajuste de dia.
  DateTime _installmentDate(DateTime purchaseDate, int installmentIndex) {
    final targetMonth = DateTime(
      purchaseDate.year,
      purchaseDate.month + (installmentIndex - 1),
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final safeDay = purchaseDate.day > lastDay ? lastDay : purchaseDate.day;
    return DateTime(targetMonth.year, targetMonth.month, safeDay);
  }

  // Gera o subtitulo exibido no card.
  String _subtitleForEntry(ExpenseEntry entry, DateFormat dateFormatter) {
    final reason = entry.reason.isEmpty ? 'Sem motivo' : entry.reason;
    if (entry.isInstallment) {
      final purchaseDate = entry.purchaseDate ?? entry.date;
      return '$reason - Parcela ${entry.installmentIndex}/${entry.installmentCount} - ${dateFormatter.format(purchaseDate)}';
    }
    final purchaseDate = entry.purchaseDate ?? entry.date;
    return '$reason - ${dateFormatter.format(purchaseDate)}';
  }

  // Gera o proximo id de entrada.
  String _nextEntryId() {
    return widget.expensesStore.nextId();
  }

  // Abre o seletor de data.
  Future<DateTime?> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    String? helpText,
  }) {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100, 12, 31),
      helpText: helpText,
    );
  }

  // Remove um gasto da subcategoria.
  void _removeEntry(ExpenseEntry entry) {
    widget.expensesStore.removeEntry(entry.id);
    _showSnack('Gasto removido');
  }

  // Exibe snackbar com feedback rapido.
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

  // Abre a tela de categorias.
  void _openCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoriesScreen(store: widget.entryCategoriesStore),
      ),
    );
  }
}

// Cabecalho com total do mes e quantidade.
class _HeaderSummary extends StatelessWidget {
  final String monthLabel;
  final String totalLabel;
  final String countLabel;

  const _HeaderSummary({
    required this.monthLabel,
    required this.totalLabel,
    required this.countLabel,
  });

  @override
  // Monta o cabecalho de resumo.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.heroGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: tokens.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: TextStyle(color: tokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
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
          AuroraBadge(label: countLabel),
        ],
      ),
    );
  }
}

// Estado vazio para subcategoria sem lancamentos.
class _EmptyEntries extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyEntries({required this.onAdd});

  @override
  // Monta o card de estado vazio.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, color: tokens.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(
              'Nenhum gasto cadastrado neste mês.',
              style: TextStyle(color: tokens.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}



