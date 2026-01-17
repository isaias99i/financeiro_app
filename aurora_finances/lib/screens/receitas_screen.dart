import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/receitas_store.dart';
import '../models/receitas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/app_settings_scope.dart';

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
    final settings = AppSettingsScope.of(context);
    final moneyFormatter = settings.currencyFormatter();

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
                monthFormatter: settings.monthYearFormatter(),
                salaryControllerFor: _controllerFor,
                onSalaryChanged: _updateSalary,
                onSalarySaved: _applySalaryFromMonth,
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

  void _applySalaryFromMonth(DateTime date) {
    final formatter = AppSettingsScope.of(context).currencyFormatter();
    final controller = _controllerFor(date, formatter);
    final value = parseCurrencyToDouble(controller.text);
    widget.store.setSalaryFromMonth(date, _endDate, value);

    for (final month in _buildMonths()) {
      if (month.isBefore(date)) {
        continue;
      }
      final key = monthKey(month);
      final existing = _salaryControllers[key];
      if (existing != null) {
        existing.text = formatter.format(value);
      }
    }
    _showSnack('Salario atualizado');
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
    final settings = AppSettingsScope.of(context);
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
            final inputDecoration = InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7FD7FF), width: 1.4),
              ),
            );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF101B24),
                      Color(0xFF183446),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFF7FD7FF)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry == null ? 'Incluir extra' : 'Editar extra',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Registre entradas fora do salario mensal.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        enableSuggestions: true,
                        autocorrect: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Descricao'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          CurrencyInputFormatter(
                            locale: settings.currencyLocale,
                            symbol: settings.currencySymbol,
                          ),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Valor'),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today, color: Colors.white70),
                          label: Text(
                            settings.dateFormatter().format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                          ),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3C8FD9),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(entry == null ? 'Adicionar' : 'Salvar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
  final DateFormat monthFormatter;
  final TextEditingController Function(DateTime, NumberFormat) salaryControllerFor;
  final void Function(DateTime, String) onSalaryChanged;
  final void Function(DateTime) onSalarySaved;
  final double Function(DateTime) extrasForMonth;

  const _MonthlyCards({
    required this.months,
    required this.moneyFormatter,
    required this.monthFormatter,
    required this.salaryControllerFor,
    required this.onSalaryChanged,
    required this.onSalarySaved,
    required this.extrasForMonth,
  });

  @override
  Widget build(BuildContext context) {
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
          onSalarySaved: () => onSalarySaved(date),
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
    final settings = AppSettingsScope.of(context);
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
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  onSalarySaved();
                }
              },
              child: TextField(
                controller: salaryController,
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
                onChanged: onSalaryChanged,
                onEditingComplete: onSalarySaved,
                onSubmitted: (_) => onSalarySaved(),
              ),
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
    final settings = AppSettingsScope.of(context);
    final dateFormatter = settings.dateFormatter();
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
              dateFormatter.format(entry.date),
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
    final formatter = AppSettingsScope.of(context).shortMonthYearFormatter();
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
