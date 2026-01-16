import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/receitas_store.dart';
import '../models/receitas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_scaffold.dart';

class ReceitasScreen extends StatefulWidget {
  final ReceitasStore store;

  const ReceitasScreen({super.key, required this.store});

  @override
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends State<ReceitasScreen>
    with SingleTickerProviderStateMixin {
  static final DateTime _startDate = DateTime(2026, 1, 1);
  static final DateTime _endDate = DateTime(2030, 12, 1);
  static const List<String> _extraSuggestions = [
    'Freelance',
    'Bonus',
    'Comissao',
    'Reembolso',
    'Venda',
  ];

  final Map<String, TextEditingController> _salaryControllers = {};
  late TabController _tabController;
  bool _showExtrasFab = false;
  DateTime? _extrasFilterMonth;

  @override
  void initState() {
    super.initState();
    if (!widget.store.isLoaded) {
      widget.store.load();
    }
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _showExtrasFab = _tabController.index == 1);
    });
  }

  @override
  void dispose() {
    for (final controller in _salaryControllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moneyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mensal'),
            Tab(text: 'Extras'),
          ],
        ),
      ),
      floatingActionButton: _showExtrasFab
          ? FloatingActionButton(
              onPressed: _showAddExtraDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          if (!widget.store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _MonthlyCards(
                months: _buildMonths(),
                moneyFormatter: moneyFormatter,
                salaryControllerFor: _controllerFor,
                onSalaryChanged: _updateSalary,
                onSalarySaved: () => _showSnack('Salario atualizado'),
                extrasForMonth: widget.store.extrasTotalForMonth,
              ),
              _ExtrasList(
                entries: widget.store.extras.toList(),
                filterMonth: _extrasFilterMonth,
                availableMonths: _buildExtrasMonths(widget.store.extras.toList()),
                onMonthChanged: (value) => setState(() => _extrasFilterMonth = value),
                formatter: moneyFormatter,
                onRemove: _removeExtra,
                onAdd: _showAddExtraDialog,
                onEdit: _showEditExtraDialog,
              ),
            ],
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

  TextEditingController _controllerFor(DateTime date, NumberFormat formatter) {
    final key = monthKey(date);
    return _salaryControllers.putIfAbsent(key, () {
      final controller = TextEditingController();
      final value = widget.store.salaryForMonth(date);
      if (value > 0) {
        controller.text = formatter.format(value);
      }
      return controller;
    });
  }

  void _updateSalary(DateTime date, String value) {
    final parsed = parseCurrencyToDouble(value);
    widget.store.setSalaryForMonth(date, parsed);
  }

  void _removeExtra(ExtraEntry entry) {
    final updated = widget.store.extras.toList()..remove(entry);
    widget.store.setExtras(updated);
    _showSnack('Extra removido');
  }

  Future<void> _showAddExtraDialog() async {
    await _showExtraDialog();
  }

  Future<void> _showEditExtraDialog(ExtraEntry entry) async {
    await _showExtraDialog(entry: entry);
  }

  Future<void> _showExtraDialog({ExtraEntry? entry}) async {
    final noteController = TextEditingController(text: entry?.note ?? '');
    final amountController = TextEditingController(
      text: entry != null ? entry.amount.toStringAsFixed(2) : '',
    );
    DateTime selectedDate = entry?.date ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar extra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: noteController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      enableSuggestions: true,
                      autocorrect: true,
                      decoration: const InputDecoration(labelText: 'Descricao'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _extraSuggestions.map((label) {
                          return ActionChip(
                            label: Text(label),
                            onPressed: () => setState(() {
                              noteController.text = label;
                              noteController.selection = TextSelection.collapsed(
                                offset: label.length,
                              );
                            }),
                          );
                        }).toList(),
                      ),
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
                    final updated = widget.store.extras.toList();
                    if (entry == null) {
                      updated.add(
                        ExtraEntry(
                          date: selectedDate,
                          amount: amount,
                          note: noteController.text.trim(),
                        ),
                      );
                    } else {
                      final index = updated.indexOf(entry);
                      if (index != -1) {
                        updated[index] = ExtraEntry(
                          date: selectedDate,
                          amount: amount,
                          note: noteController.text.trim(),
                        );
                      }
                    }
                    widget.store.setExtras(updated);
                    Navigator.pop(context);
                    _showSnack(entry == null ? 'Extra adicionado' : 'Extra atualizado');
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

  Future<DateTime?> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
  }) {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100, 12, 31),
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

  List<DateTime> _buildExtrasMonths(List<ExtraEntry> entries) {
    final months = <DateTime>{};
    for (final entry in entries) {
      months.add(DateTime(entry.date.year, entry.date.month, 1));
    }
    final sorted = months.toList()
      ..sort((a, b) => b.compareTo(a));
    return sorted;
  }
}

class _MonthlyCards extends StatelessWidget {
  final List<DateTime> months;
  final NumberFormat moneyFormatter;
  final TextEditingController Function(DateTime, NumberFormat) salaryControllerFor;
  final void Function(DateTime, String) onSalaryChanged;
  final VoidCallback onSalarySaved;
  final double Function(DateTime) extrasForMonth;

  const _MonthlyCards({
    required this.months,
    required this.moneyFormatter,
    required this.salaryControllerFor,
    required this.onSalaryChanged,
    required this.onSalarySaved,
    required this.extrasForMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthFormatter = DateFormat('MMMM yyyy', 'pt_BR');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: months.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final date = months[index];
        final salario = salaryControllerFor(date, moneyFormatter);
        final extras = extrasForMonth(date);
        final salarioValue = parseCurrencyToDouble(salario.text);
        final total = salarioValue + extras;

        return _ReceitaCard(
          title: monthFormatter.format(date),
          salaryController: salario,
          onSalaryChanged: (value) => onSalaryChanged(date, value),
          onSalarySaved: onSalarySaved,
          extrasLabel: moneyFormatter.format(extras),
          totalLabel: moneyFormatter.format(total),
        );
      },
    );
  }
}

class _ReceitaCard extends StatelessWidget {
  final String title;
  final TextEditingController salaryController;
  final ValueChanged<String> onSalaryChanged;
  final VoidCallback onSalarySaved;
  final String extrasLabel;
  final String totalLabel;

  const _ReceitaCard({
    required this.title,
    required this.salaryController,
    required this.onSalaryChanged,
    required this.onSalarySaved,
    required this.extrasLabel,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _ReceitaRow(
            label: 'Salario',
            child: TextField(
              controller: salaryController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                CurrencyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
              ],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '0,00',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              onChanged: onSalaryChanged,
              onEditingComplete: onSalarySaved,
            ),
          ),
          const SizedBox(height: 8),
          _ReceitaRow(
            label: 'Extras',
            child: Text(
              extrasLabel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          _ReceitaRow(
            label: 'Total',
            child: Text(
              totalLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceitaRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _ReceitaRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ExtrasList extends StatelessWidget {
  final List<ExtraEntry> entries;
  final List<DateTime> availableMonths;
  final DateTime? filterMonth;
  final ValueChanged<DateTime?> onMonthChanged;
  final NumberFormat formatter;
  final void Function(ExtraEntry entry) onRemove;
  final VoidCallback onAdd;
  final void Function(ExtraEntry entry) onEdit;

  const _ExtrasList({
    required this.entries,
    required this.availableMonths,
    required this.filterMonth,
    required this.onMonthChanged,
    required this.formatter,
    required this.onRemove,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = filterMonth == null
        ? entries
        : entries
            .where(
              (entry) =>
                  entry.date.year == filterMonth!.year &&
                  entry.date.month == filterMonth!.month,
            )
            .toList();
    final sorted = List<ExtraEntry>.from(filtered)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.isEmpty ? 1 : sorted.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ExtrasFilterBar(
            months: availableMonths,
            selected: filterMonth,
            onChanged: onMonthChanged,
          );
        }
        if (sorted.isEmpty) {
          return _EmptyExtras(onAdd: onAdd);
        }
        final entry = sorted[index - 1];
        return Card(
          color: Colors.white.withValues(alpha: 0.08),
          child: ListTile(
            onTap: () => onEdit(entry),
            title: Text(
              entry.note.isEmpty ? 'Extra' : entry.note,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(entry.date),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatter.format(entry.amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onRemove(entry),
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExtrasFilterBar extends StatelessWidget {
  final List<DateTime> months;
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const _ExtrasFilterBar({
    required this.months,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM/yyyy', 'pt_BR');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime?>(
                value: selected,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F2C3E),
                icon: const Icon(Icons.expand_more, color: Colors.white70),
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem<DateTime?>(
                    value: null,
                    child: Text('Todos os meses'),
                  ),
                  for (final month in months)
                    DropdownMenuItem<DateTime?>(
                      value: month,
                      child: Text(formatter.format(month)),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExtras extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyExtras({required this.onAdd});

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
            const Icon(Icons.savings, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Nenhum extra registrado.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar extra'),
            ),
          ],
        ),
      ),
    );
  }
}
