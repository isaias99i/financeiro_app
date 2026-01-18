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

// Tela de lancamentos detalhados de uma coluna.
class DespesaColunaScreen extends StatefulWidget {
  final DespesasStore store;
  final CategoriesStore categoriesStore;
  final ExpenseGroup group;
  final ExpenseColumn column;
  final DateTime initialMonth;

  const DespesaColunaScreen({
    super.key,
    required this.store,
    required this.categoriesStore,
    required this.group,
    required this.column,
    required this.initialMonth,
  });

  @override
  // Cria o estado da tela de coluna.
  State<DespesaColunaScreen> createState() => _DespesaColunaScreenState();
}

// Estado da coluna com filtro por mes.
class _DespesaColunaScreenState extends State<DespesaColunaScreen> {
  late DateTime _selectedMonth;

  @override
  // Inicializa o mes selecionado e categorias.
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
      1,
    );
    if (!widget.categoriesStore.isLoaded) {
      widget.categoriesStore.load();
    }
  }

  @override
  // Monta a UI com lista de lancamentos.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final dateFormatter = settings.dateFormatter();
    final monthFormatter = settings.monthYearFormatter();
    final moneyFormatter = settings.currencyFormatter();

    return AuroraScaffold(
      appBar: AppBar(
        title: Text(widget.column.title),
        actions: [
          IconButton(
            onPressed: () => _pickMonth(context),
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Alterar mes',
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
        animation: widget.store,
        builder: (context, _) {
          final entries = _entriesForMonth();
          final total = entries.fold<double>(0.0, (sum, entry) => sum + entry.amount);

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
                  child: entries.isEmpty
                      ? _EmptyEntries(onAdd: _showAddDialog)
                      : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Card(
                              color: Colors.white.withValues(alpha: 0.08),
                              child: ListTile(
                                onTap: () => _showEditDialog(entry),
                                leading: const Icon(Icons.receipt_long, color: Colors.white70),
                                title: Text(
                                  entry.category.isEmpty ? 'Sem categoria' : entry.category,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  _subtitleForEntry(entry, dateFormatter),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      moneyFormatter.format(entry.amount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      onPressed: () => _removeEntry(entry),
                                      icon: const Icon(Icons.delete_outline, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Filtra e ordena entradas do mes.
  List<ExpenseEntry> _entriesForMonth() {
    final entries = widget.store.entriesForColumn(widget.column);
    final filtered = entries
        .where((entry) => isSameMonth(entry.date, _selectedMonth))
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
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
    final amountController = TextEditingController(
      text: entry != null ? entry.amount.toStringAsFixed(2) : '',
    );
    DateTime selectedDate = entry?.date ?? _selectedMonth;
    bool isInstallment = entry?.isInstallment ?? false;
    final installmentCountController = TextEditingController(
      text: entry?.installmentCount?.toString() ?? '1',
    );
    final installmentIndexController = TextEditingController(
      text: entry?.installmentIndex?.toString() ?? '1',
    );
    DateTime purchaseDate = entry?.purchaseDate ?? _selectedMonth;
    final categoryList = widget.categoriesStore.categories.toList();
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
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nenhuma categoria cadastrada.',
                              style: TextStyle(color: Colors.white),
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
                          label: Text(settings.dateFormatter().format(selectedDate)),
                          onPressed: () async {
                            final picked = await _pickDate(
                              context: context,
                              initialDate: selectedDate,
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
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
                        amount: amount,
                        category: selectedCategory ?? '',
                        reason: reasonController.text.trim(),
                      );
                    } else {
                      if (entry == null) {
                        widget.store.addEntry(
                          ExpenseEntry(
                            id: _nextEntryId(),
                            columnId: widget.column.id,
                            date: selectedDate,
                            category: selectedCategory ?? '',
                            reason: reasonController.text.trim(),
                            amount: amount,
                          ),
                        );
                      } else {
                        widget.store.updateEntry(
                          entry.id,
                          entry.copyWith(
                            date: selectedDate,
                            category: selectedCategory ?? '',
                            reason: reasonController.text.trim(),
                            amount: amount,
                            installmentCount: null,
                            installmentIndex: null,
                            purchaseDate: null,
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
      widget.store.updateEntry(
        entry.id,
        entry.copyWith(
          date: _installmentDate(purchaseDate, index),
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
      widget.store.addEntry(
        ExpenseEntry(
          id: _nextEntryId(),
          columnId: widget.column.id,
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
      return '$reason - Parcela ${entry.installmentIndex}/${entry.installmentCount} - ${dateFormatter.format(entry.date)}';
    }
    return '$reason - ${dateFormatter.format(entry.date)}';
  }

  // Gera o proximo id de entrada.
  String _nextEntryId() {
    return widget.store.nextId();
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

  // Remove um gasto da coluna.
  void _removeEntry(ExpenseEntry entry) {
    widget.store.removeEntry(entry.id);
    _showSnack('Gasto removido');
  }

  // Exibe snackbar com feedback rapido.
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

  // Abre a tela de categorias.
  void _openCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasScreen(store: widget.categoriesStore),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C8EC9).withValues(alpha: 0.22),
            const Color(0xFF1FAF86).withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          AuroraBadge(label: countLabel),
        ],
      ),
    );
  }
}

// Estado vazio para coluna sem lancamentos.
class _EmptyEntries extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyEntries({required this.onAdd});

  @override
  // Monta o card de estado vazio.
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
            const Icon(Icons.receipt_long, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Nenhum gasto cadastrado neste mês.',
              style: TextStyle(color: Colors.white),
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



