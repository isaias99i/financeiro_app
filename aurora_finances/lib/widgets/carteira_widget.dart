import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/carteira_store.dart';
import '../models/carteira_models.dart';

class CarteiraWidget extends StatefulWidget {
  final CarteiraStore store;

  const CarteiraWidget({required this.store, super.key});

  @override
  State<CarteiraWidget> createState() => _CarteiraWidgetState();
}

class _CarteiraWidgetState extends State<CarteiraWidget> {
  bool _isExpanded = false;
  final List<Color> _colorOptions = const [
    Color(0xFF1C8EC9),
    Color(0xFF1FAF86),
    Color(0xFFE19932),
    Color(0xFFE36A4F),
    Color(0xFF3D5BA9),
    Color(0xFF254A6A),
    Color(0xFF8E44AD),
    Color(0xFF2ECC71),
  ];

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = widget.store.totalBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Carteira',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const Spacer(),
            Text(
              format.format(total),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Saldo atual do mes',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
        const SizedBox(height: 10),
        ExpansionPanelList(
          elevation: 0,
          dividerColor: Colors.white.withValues(alpha: 0.1),
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          children: [
            ExpansionPanel(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              isExpanded: _isExpanded,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text(
                    'Bancos',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  trailing: IconButton(
                    onPressed: _showAddBankDialog,
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    for (final bank in widget.store.banks)
                      _BankCard(
                        bank: bank,
                        onEdit: () => _showEditBankDialog(bank),
                        onRemove: () => widget.store.removeBank(bank.id),
                      ),
                    const SizedBox(height: 6),
                    _AddBankCard(onTap: _showAddBankDialog),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddBankDialog() {
    _showBankDialog();
  }

  void _showEditBankDialog(BankAccount bank) {
    _showBankDialog(existing: bank);
  }

  void _showBankDialog({BankAccount? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final balanceController = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(2) : '',
    );
    Color selectedColor =
        existing != null ? Color(existing.colorValue) : _colorOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Adicionar banco' : 'Editar banco'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Saldo'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cor',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((color) {
                        final isSelected =
                            color.toARGB32() == selectedColor.toARGB32();
                        return InkWell(
                          onTap: () => setState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    final raw = balanceController.text.trim().replaceAll(',', '.');
                    final balance = double.tryParse(raw) ?? 0.0;

                    if (existing == null) {
                      final bank = BankAccount(
                        id: widget.store.nextId(),
                        name: name,
                        balance: balance,
                        colorValue: selectedColor.toARGB32(),
                      );
                      widget.store.addBank(bank);
                    } else {
                      widget.store.updateBank(
                        existing.id,
                        existing.copyWith(
                          name: name,
                          balance: balance,
                          colorValue: selectedColor.toARGB32(),
                        ),
                      );
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text(existing == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BankCard extends StatelessWidget {
  final BankAccount bank;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _BankCard({
    required this.bank,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onEdit,
        leading: Container(
          width: 12,
          height: 36,
          decoration: BoxDecoration(
            color: Color(bank.colorValue),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(bank.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          format.format(bank.balance),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, color: Colors.white70),
        ),
      ),
    );
  }
}

class _AddBankCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBankCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white70),
              SizedBox(width: 6),
              Text('Adicionar banco', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
