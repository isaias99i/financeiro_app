import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/receitas_store.dart';
import '../models/receitas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/month_key.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_tokens.dart';

// Tela de receitas com salario e extras.
class ReceitasScreen extends StatefulWidget {
  final ReceitasStore store;

  const ReceitasScreen({super.key, required this.store});

  @override
  // Cria o estado da tela de receitas.
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

// Estado das receitas com tabs de salario e extras.
class _ReceitasScreenState extends State<ReceitasScreen>
    with SingleTickerProviderStateMixin {
  static final DateTime _startDate = DateTime(2026, 1, 1);
  static final DateTime _endDate = DateTime(2030, 12, 1);
  final Map<String, TextEditingController> _salaryControllers = {};
  late TabController _tabController;
  bool _showExtrasFab = false;
  DateTime? _extrasFilterMonth;

  @override
  // Inicializa o store e o controle de tabs.
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
  // Libera controllers do salario e tab.
  void dispose() {
    for (final controller in _salaryControllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  // Monta a UI principal das receitas.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    final moneyFormatter = settings.currencyFormatter();

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: tokens.accent,
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

  // Lista meses entre datas limite.
  List<DateTime> _buildMonths() {
    final months = <DateTime>[];
    var current = _startDate;
    while (!current.isAfter(_endDate)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return months;
  }

  // Retorna controller do salario para o mes.
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

  // Atualiza salario do mes atual.
  void _updateSalary(DateTime date, String value) {
    final parsed = parseCurrencyToDouble(value);
    widget.store.setSalaryForMonth(date, parsed);
  }

  // Aplica salario fixo a partir de um mes.
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

  // Remove uma entrada extra.
  void _removeExtra(ExtraEntry entry) {
    final updated = widget.store.extras.toList()..remove(entry);
    widget.store.setExtras(updated);
    _showSnack('Extra removido');
  }

  // Abre dialogo para adicionar extra.
  Future<void> _showAddExtraDialog() async {
    await _showExtraDialog();
  }

  // Abre dialogo para editar extra.
  Future<void> _showEditExtraDialog(ExtraEntry entry) async {
    await _showExtraDialog(entry: entry);
  }

  // Dialogo principal de extra.
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
            final tokens = AppThemeTokens.of(context);
            final inputDecoration = InputDecoration(
              filled: true,
              fillColor: tokens.surfaceAlt,
              labelStyle: TextStyle(color: tokens.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.focus, width: 1.4),
              ),
            );

            return Dialog(
              backgroundColor: tokens.background.withValues(alpha: 0.0),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tokens.panelGradient,
                  ),
                  border: Border.all(color: tokens.border),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.shadow,
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
                              color: tokens.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_awesome, color: tokens.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry == null ? 'Incluir extra' : 'Editar extra',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Registre entradas fora do salario mensal.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: tokens.textSecondary),
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
                        style: TextStyle(color: tokens.textPrimary),
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
                        style: TextStyle(color: tokens.textPrimary),
                        decoration: inputDecoration.copyWith(labelText: 'Valor'),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: Icon(Icons.calendar_today, color: tokens.textSecondary),
                          label: Text(
                            settings.dateFormatter().format(selectedDate),
                            style: TextStyle(color: tokens.textPrimary),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: tokens.surfaceAlt,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: tokens.border),
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
                                foregroundColor: tokens.textSecondary,
                                side: BorderSide(color: tokens.border),
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
                                backgroundColor: tokens.accent,
                                foregroundColor: tokens.textPrimary,
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
  // Abre o seletor de data.
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

  // Monta lista de meses com extras.
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

// Lista de cards mensais de salario.
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
  // Monta a lista de meses.
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

// Card de receita mensal com totais.
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
  // Monta o card de receita.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: tokens.textPrimary,
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
                style: TextStyle(color: tokens.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '0,00',
                  hintStyle: TextStyle(color: tokens.textMuted),
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
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          _ReceitaRow(
            label: 'Total',
            child: Text(
              totalLabel,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Linha simples de label e valor.
class _ReceitaRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _ReceitaRow({
    required this.label,
    required this.child,
  });

  @override
  // Monta a linha de label/valor.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: tokens.textSecondary),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// Lista de entradas extras com filtro.
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
  // Monta a lista de extras e filtros.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
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
          color: tokens.surfaceAlt,
          child: ListTile(
            onTap: () => onEdit(entry),
            title: Text(
              entry.note.isEmpty ? 'Extra' : entry.note,
              style: TextStyle(color: tokens.textPrimary),
            ),
            subtitle: Text(
              dateFormatter.format(entry.date),
              style: TextStyle(color: tokens.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatter.format(entry.amount),
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onRemove(entry),
                  icon: Icon(Icons.delete_outline, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Barra de filtro por mes dos extras.
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
  // Monta o filtro de meses.
  Widget build(BuildContext context) {
    final formatter = AppSettingsScope.of(context).shortMonthYearFormatter();
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: tokens.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime?>(
                value: selected,
                isExpanded: true,
                dropdownColor: tokens.surface,
                icon: Icon(Icons.expand_more, color: tokens.textSecondary),
                style: TextStyle(color: tokens.textPrimary),
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

// Estado vazio para lista de extras.
class _EmptyExtras extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyExtras({required this.onAdd});

  @override
  // Monta o estado vazio de extras.
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
            Icon(Icons.savings, color: tokens.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(
              'Nenhum extra registrado.',
              style: TextStyle(color: tokens.textPrimary),
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
