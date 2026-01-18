import 'package:flutter/material.dart';
import '../models/receitas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_tokens.dart';

// Tela simples para listar e editar extras.
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
  // Cria o estado da tela de extras.
  State<ExtrasScreen> createState() => _ExtrasScreenState();
}

// Estado da tela de extras com filtro opcional.
class _ExtrasScreenState extends State<ExtrasScreen> {
  late List<ExtraEntry> _entries;

  @override
  // Inicializa a lista local de extras.
  void initState() {
    super.initState();
    _entries = List<ExtraEntry>.from(widget.initialEntries);
  }

  @override
  // Monta a lista de extras.
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tokens = AppThemeTokens.of(context);
    final formatter = settings.dateFormatter();
    final title = widget.filterMonth == null
        ? 'Extras'
        : 'Extras ${settings.numericMonthYearFormatter().format(widget.filterMonth!)}';
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
            color: tokens.surfaceAlt,
            child: ListTile(
              title: Text(
                entry.note.isEmpty ? 'Extra' : entry.note,
                style: TextStyle(color: tokens.textPrimary),
              ),
              subtitle: Text(
                formatter.format(entry.date),
                style: TextStyle(color: tokens.textSecondary),
              ),
              trailing: Text(
                settings.currencyFormatter().format(entry.amount),
                style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600),
              ),
              leading: Icon(Icons.star, color: tokens.textPrimary),
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

  // Abre dialogo para adicionar extra.
  Future<void> _showAddDialog() async {
    final settings = AppSettingsScope.of(context);
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
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                enableSuggestions: true,
                autocorrect: true,
                decoration: const InputDecoration(labelText: 'Descricao'),
              ),
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

  // Aplica filtro de mes se existir.
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
