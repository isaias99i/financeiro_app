import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/receitas_store.dart';
import '../models/receitas_models.dart';
import '../utils/month_key.dart';
import '../screens/extras_screen.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/aurora_scaffold.dart';

class ReceitasScreen extends StatefulWidget {
  final ReceitasStore store;

  const ReceitasScreen({super.key, required this.store});

  @override
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends State<ReceitasScreen> {
  static final DateTime _startDate = DateTime(2026, 1, 1);
  static final DateTime _endDate = DateTime(2030, 12, 1);

  final Map<String, TextEditingController> _salaryControllers = {};

  @override
  void initState() {
    super.initState();
    if (!widget.store.isLoaded) {
      widget.store.load();
    }
  }

  @override
  void dispose() {
    for (final controller in _salaryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> headers = [
      'Geral',
      'Salario',
      'Extras',
      'Total',
    ];
    final monthFormatter = DateFormat('MM/yyyy');
    final moneyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          if (!widget.store.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final months = _buildMonths();
          final rows = months.map((date) {
            final extrasTotal = widget.store.extrasTotalForMonth(date);
            final salario = widget.store.salaryForMonth(date);
            final total = salario + extrasTotal;
            return _ReceitaRow(
              date: date,
              label: monthFormatter.format(date),
              salario: salario,
              extras: extrasTotal,
              total: total,
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: headers.map((header) {
                      return Container(
                        width: 140,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          header,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                  ...rows.map((row) {
                    return Row(
                      children: [
                        _ValueCell(
                          width: 140,
                          value: row.label,
                          align: TextAlign.center,
                        ),
                        _SalaryInputCell(
                          width: 140,
                          controller: _controllerFor(row.date, moneyFormatter),
                          onChanged: (value) => _updateSalary(row.date, value),
                        ),
                        _ExtrasCell(
                          width: 140,
                          value: moneyFormatter.format(row.extras),
                          onTap: () => _openExtras(row.date),
                        ),
                        _ValueCell(
                          width: 140,
                          value: moneyFormatter.format(row.total),
                        ),
                      ],
                    );
                  }),
                ],
              ),
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

  Future<void> _openExtras(DateTime month) async {
    final result = await Navigator.push<List<ExtraEntry>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExtrasScreen(
          initialEntries: widget.store.extras.toList(),
          filterMonth: month,
          initialDate: month,
        ),
      ),
    );
    if (result != null) {
      widget.store.setExtras(result);
    }
  }
}

class _ReceitaRow {
  final DateTime date;
  final String label;
  final double salario;
  final double extras;
  final double total;

  _ReceitaRow({
    required this.date,
    required this.label,
    required this.salario,
    required this.extras,
    required this.total
  });
}

class _SalaryInputCell extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SalaryInputCell({
    required this.width,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
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

class _ValueCell extends StatelessWidget {
  final double width;
  final String value;
  final TextAlign align;

  const _ValueCell({
    required this.width,
    required this.value,
    this.align = TextAlign.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        value,
        textAlign: align,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _ExtrasCell extends StatelessWidget {
  final double width;
  final String value;
  final VoidCallback onTap;

  const _ExtrasCell({
    required this.width,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
