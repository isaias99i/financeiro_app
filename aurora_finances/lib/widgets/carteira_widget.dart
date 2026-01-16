import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/carteira_store.dart';
import '../models/carteira_models.dart';
import '../utils/currency_input_formatter.dart';

class CarteiraWidget extends StatefulWidget {
  final CarteiraStore store;
  final double? expectedBalance;

  const CarteiraWidget({
    required this.store,
    this.expectedBalance,
    super.key,
  });

  @override
  State<CarteiraWidget> createState() => _CarteiraWidgetState();
}

class _CarteiraWidgetState extends State<CarteiraWidget> {
  bool _isExpanded = false;
  _SortMode _sortMode = _SortMode.balanceDesc;
  final Set<String> _editingIds = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _balanceControllers = {};
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
    final status = _buildStatus(total, widget.expectedBalance, format);
    final banks = _sortedBanks(widget.store.banks);

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
        if (status != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<_SortMode>(
                        onSelected: (mode) => setState(() => _sortMode = mode),
                        icon: const Icon(Icons.sort, color: Colors.white),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _SortMode.balanceDesc,
                            child: Text('Maior saldo'),
                          ),
                          PopupMenuItem(
                            value: _SortMode.balanceAsc,
                            child: Text('Menor saldo'),
                          ),
                          PopupMenuItem(
                            value: _SortMode.nameAsc,
                            child: Text('Nome (A-Z)'),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _showAddBankDialog,
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    for (final bank in banks)
                      _BankCard(
                        bank: bank,
                        totalBalance: total,
                        isEditing: _editingIds.contains(bank.id),
                        nameController: _nameControllerFor(bank),
                        balanceController: _balanceControllerFor(bank, format),
                        onEdit: () => _startInlineEdit(bank),
                        onSave: () => _saveInlineEdit(bank),
                        onCancel: () => _cancelInlineEdit(bank),
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

  _StatusInfo? _buildStatus(
    double total,
    double? expected,
    NumberFormat formatter,
  ) {
    if (expected == null) {
      return null;
    }
    final expectedLabel = formatter.format(expected);
    final diff = total - expected;
    if (diff.abs() < 0.01) {
      return _StatusInfo(
        label: 'Dentro do esperado ($expectedLabel)',
        color: const Color(0xFF1FAF86),
      );
    }
    if (diff > 0) {
      return _StatusInfo(
        label: 'Acima do esperado ($expectedLabel)',
        color: const Color(0xFFE36A4F),
      );
    }
    return _StatusInfo(
      label: 'Abaixo do esperado ($expectedLabel)',
      color: const Color(0xFF1C8EC9),
    );
  }

  List<BankAccount> _sortedBanks(List<BankAccount> banks) {
    final list = List<BankAccount>.from(banks);
    switch (_sortMode) {
      case _SortMode.balanceDesc:
        list.sort((a, b) => b.balance.compareTo(a.balance));
        break;
      case _SortMode.balanceAsc:
        list.sort((a, b) => a.balance.compareTo(b.balance));
        break;
      case _SortMode.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return list;
  }

  TextEditingController _nameControllerFor(BankAccount bank) {
    return _nameControllers.putIfAbsent(
      bank.id,
      () => TextEditingController(text: bank.name),
    );
  }

  TextEditingController _balanceControllerFor(
    BankAccount bank,
    NumberFormat formatter,
  ) {
    return _balanceControllers.putIfAbsent(
      bank.id,
      () {
        final controller = TextEditingController();
        if (bank.balance > 0) {
          controller.text = formatter.format(bank.balance);
        }
        return controller;
      },
    );
  }

  void _startInlineEdit(BankAccount bank) {
    setState(() {
      _editingIds.add(bank.id);
    });
  }

  void _cancelInlineEdit(BankAccount bank) {
    setState(() {
      _editingIds.remove(bank.id);
    });
  }

  void _saveInlineEdit(BankAccount bank) {
    final name = _nameControllerFor(bank).text.trim();
    final balance = parseCurrencyToDouble(
      _balanceControllerFor(
        bank,
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$'),
      ).text,
    );
    if (name.isEmpty) {
      return;
    }
    widget.store.updateBank(
      bank.id,
      bank.copyWith(name: name, balance: balance),
    );
    setState(() {
      _editingIds.remove(bank.id);
    });
    _showSnack(context, 'Banco atualizado');
  }

  void _showAddBankDialog() {
    _showBankDialog();
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }

  void _showEditBankDialog(BankAccount bank) {
    _showBankDialog(existing: bank);
  }

  void _showBankDialog({BankAccount? existing}) {
    final rootContext = context;
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
                      inputFormatters: [
                        CurrencyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
                      ],
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
                    final balance = parseCurrencyToDouble(balanceController.text);

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
                    _showSnack(rootContext, 'Banco salvo');
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
  final double totalBalance;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const _BankCard({
    required this.bank,
    required this.totalBalance,
    required this.isEditing,
    required this.nameController,
    required this.balanceController,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final ratio = totalBalance <= 0 ? 0.0 : (bank.balance / totalBalance).clamp(0.0, 1.0);
    final percent = (ratio * 100).toStringAsFixed(0);

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isEditing ? null : onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(bank.colorValue),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing)
                      TextField(
                        controller: nameController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Nome do banco',
                          hintStyle: TextStyle(color: Colors.white54),
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        bank.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 4),
                    if (isEditing)
                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          CurrencyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
                        ],
                        maxLines: 1,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Saldo',
                          hintStyle: TextStyle(color: Colors.white54),
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(color: Colors.white70),
                      )
                    else
                      Text(
                        format.format(bank.balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(bank.colorValue)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percent% do total',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: isEditing
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: onSave,
                            icon: const Icon(Icons.check, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      )
                    : IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      ),
              ),
            ],
          ),
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

class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.color,
  });
}

enum _SortMode {
  balanceDesc,
  balanceAsc,
  nameAsc,
}
