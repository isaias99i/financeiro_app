import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../models/despesas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_badge.dart';
import '../widgets/aurora_scaffold.dart';

class DespesaColunaScreen extends StatefulWidget {
  final DespesasStore store;
  final ExpenseGroup group;
  final ExpenseColumn column;
  final DateTime initialMonth;

  const DespesaColunaScreen({
    super.key,
    required this.store,
    required this.group,
    required this.column,
    required this.initialMonth,
  });

  @override
  State<DespesaColunaScreen> createState() => _DespesaColunaScreenState();
}

class _DespesaColunaScreenState extends State<DespesaColunaScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final monthFormatter = DateFormat('MMMM yyyy', 'pt_BR');
    final moneyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AuroraScaffold(
      appBar: AppBar(
        title: Text(widget.column.title),
        actions: [
          IconButton(
            onPressed: () => _pickMonth(context),
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Alterar mes',
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
                      ? const _EmptyEntries()
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
                                      onPressed: () => widget.store.removeEntry(entry.id),
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

  List<ExpenseEntry> _entriesForMonth() {
    final entries = widget.store.entriesForColumn(widget.column);
    final filtered = entries
        .where((entry) => isSameMonth(entry.date, _selectedMonth))
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

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

  Future<void> _showAddDialog() async {
    await _showEntryDialog();
  }

  Future<void> _showEditDialog(ExpenseEntry entry) async {
    await _showEntryDialog(entry: entry);
  }

  Future<void> _showEntryDialog({ExpenseEntry? entry}) async {
    final categoryController = TextEditingController(text: entry?.category ?? '');
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
                    TextField(
                      controller: categoryController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      enableSuggestions: true,
                      autocorrect: true,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 8),
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
                        CurrencyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
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
                                'Data da compra: ${DateFormat('dd/MM/yyyy').format(purchaseDate)}',
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
                          label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                        category: categoryController.text.trim(),
                        reason: reasonController.text.trim(),
                      );
                    } else {
                      if (entry == null) {
                        widget.store.addEntry(
                          ExpenseEntry(
                            id: _nextEntryId(),
                            columnId: widget.column.id,
                            date: selectedDate,
                            category: categoryController.text.trim(),
                            reason: reasonController.text.trim(),
                            amount: amount,
                          ),
                        );
                      } else {
                        widget.store.updateEntry(
                          entry.id,
                          entry.copyWith(
                            date: selectedDate,
                            category: categoryController.text.trim(),
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

  String _subtitleForEntry(ExpenseEntry entry, DateFormat dateFormatter) {
    final reason = entry.reason.isEmpty ? 'Sem motivo' : entry.reason;
    if (entry.isInstallment) {
      return '$reason - Parcela ${entry.installmentIndex}/${entry.installmentCount} - ${dateFormatter.format(entry.date)}';
    }
    return '$reason - ${dateFormatter.format(entry.date)}';
  }

  String _nextEntryId() {
    return widget.store.nextId();
  }

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

}

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

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries();

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
        child: const Text(
          'Nenhum gasto cadastrado neste mes.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


