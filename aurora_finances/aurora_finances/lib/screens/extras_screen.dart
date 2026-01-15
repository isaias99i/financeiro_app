import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receitas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/aurora_scaffold.dart';

class ExtrasScreen extends StatefulWidget {
  final List<ExtraEntry> initialEntries;
  final DateTime? filterMonth;
  final DateTime? initialDate;

  const ExtrasScreen({
    super.key,
    required this.initialEntries,
    this.filterMonth,
    this.initialDate,
  });

  @override
  State<ExtrasScreen> createState() => _ExtrasScreenState();
}

class _ExtrasScreenState extends State<ExtrasScreen> {
  late List<ExtraEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<ExtraEntry>.from(widget.initialEntries);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final title = widget.filterMonth == null
        ? 'Extras'
        : 'Extras ${DateFormat('MM/yyyy').format(widget.filterMonth!)}';
    final entries = _visibleEntries();

    return AuroraScaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _entries),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            color: Colors.white.withValues(alpha: 0.08),
            child: ListTile(
              title: Text(
                entry.note.isEmpty ? 'Extra' : entry.note,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                formatter.format(entry.date),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              trailing: Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(entry.amount),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              leading: const Icon(Icons.star, color: Colors.white),
              onLongPress: () {
                setState(() {
                  _entries.remove(entry);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate =
        widget.initialDate ?? widget.filterMonth ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar extra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Descricao'),
              ),
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
                  label: const Text('Selecionar data'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                ),
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
                final amount = parseCurrencyToDouble(amountController.text);
                if (amount <= 0 || selectedDate == null) {
                  return;
                }
                setState(() {
                  _entries.add(
                    ExtraEntry(
                      date: selectedDate!,
                      amount: amount,
                      note: noteController.text.trim(),
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  List<ExtraEntry> _visibleEntries() {
    final filter = widget.filterMonth;
    if (filter == null) {
      return _entries;
    }
    return _entries
        .where((entry) => entry.date.year == filter.year && entry.date.month == filter.month)
        .toList();
  }
}
