import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/carteira_store.dart';
import '../models/carteira_models.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_layout.dart';
import '../theme/app_tokens.dart';

// Widget da carteira com lista de bancos e saldo total.
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

// Estado com ordenacao, edicao inline e expand/collapse.
class _CarteiraWidgetState extends State<CarteiraWidget> {
  bool _isExpanded = false;
  _SortMode _sortMode = _SortMode.balanceDesc;
  final Set<String> _editingIds = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _balanceControllers = {};
  List<Color> _colorOptions(AppThemeTokens tokens) => tokens.metricPaletteColors;

  // Monta a UI da carteira com grafico e lista.
  @override
  Widget build(BuildContext context) {
    final format = AppSettingsScope.of(context).currencyFormatter();
    final tokens = AppThemeTokens.of(context);
    final total = widget.store.totalBalance;
    final status = _buildStatus(total, widget.expectedBalance, format, tokens);
    final banks = _sortedBanks(widget.store.banks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Carteira',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              format.format(total),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Saldo atual do mes',
          style: TextStyle(color: tokens.textSecondary, fontSize: 12),
        ),
        if (status != null) ...[
          const SizedBox(height: AppLayout.spaceSm),
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
              const SizedBox(width: AppLayout.spaceSm),
              Text(
                status.label,
                style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        if (banks.isNotEmpty && total > 0) ...[
          const SizedBox(height: AppLayout.spaceMd),
          _PieCard(banks: banks, total: total, formatter: format),
        ],
        const SizedBox(height: AppLayout.spaceMd),
        ExpansionPanelList(
          elevation: 0,
          dividerColor: tokens.border,
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          children: [
            ExpansionPanel(
              backgroundColor: tokens.surfaceAlt,
              isExpanded: _isExpanded,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.spaceLg,
                    vertical: AppLayout.spaceXs,
                  ),
                  title: Text(
                    'Bancos',
                    style: TextStyle(fontWeight: FontWeight.w600, color: tokens.textPrimary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<_SortMode>(
                        onSelected: (mode) => setState(() => _sortMode = mode),
                        icon: Icon(Icons.sort, color: tokens.textPrimary),
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
                        icon: Icon(Icons.add_circle, color: tokens.textPrimary),
                      ),
                    ],
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.spaceMd,
                  0,
                  AppLayout.spaceMd,
                  AppLayout.spaceMd,
                ),
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
                    const SizedBox(height: AppLayout.spaceSm),
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

  // Calcula status visual comparando saldo com o esperado.
  _StatusInfo? _buildStatus(
    double total,
    double? expected,
    NumberFormat formatter,
    AppThemeTokens tokens,
  ) {
    if (expected == null) {
      return null;
    }
    final expectedLabel = formatter.format(expected);
    final diff = total - expected;
    if (diff.abs() < 0.01) {
      return _StatusInfo(
        label: 'Dentro do esperado ($expectedLabel)',
        color: tokens.success,
      );
    }
    if (diff > 0) {
      return _StatusInfo(
        label: 'Acima do esperado ($expectedLabel)',
        color: tokens.danger,
      );
    }
    return _StatusInfo(
      label: 'Abaixo do esperado ($expectedLabel)',
      color: tokens.primary,
    );
  }

  // Ordena bancos conforme o modo selecionado.
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

  // Controlador de nome por banco.
  TextEditingController _nameControllerFor(BankAccount bank) {
    return _nameControllers.putIfAbsent(
      bank.id,
      () => TextEditingController(text: bank.name),
    );
  }

  // Controlador de saldo por banco.
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

  // Inicia edicao inline.
  void _startInlineEdit(BankAccount bank) {
    setState(() {
      _editingIds.add(bank.id);
    });
  }

  // Cancela edicao inline.
  void _cancelInlineEdit(BankAccount bank) {
    setState(() {
      _editingIds.remove(bank.id);
    });
  }

  // Salva edicao inline no store.
  void _saveInlineEdit(BankAccount bank) {
    final settings = AppSettingsScope.of(context);
    final name = _nameControllerFor(bank).text.trim();
    final balance = parseCurrencyToDouble(
      _balanceControllerFor(
        bank,
        NumberFormat.currency(
          locale: settings.currencyLocale,
          symbol: settings.currencySymbol,
        ),
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

  // Abre dialogo para adicionar banco.
  void _showAddBankDialog() {
    _showBankDialog();
  }

  // Mostra mensagem rapida.
  void _showSnack(BuildContext context, String message) {
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

  // Dialogo para criar/editar banco.
  void _showBankDialog({BankAccount? existing}) {
    final rootContext = context;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final balanceController = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(2) : '',
    );
    final tokens = AppThemeTokens.of(context);
    Color selectedColor = existing != null
        ? Color(existing.colorValue)
        : _colorOptions(tokens).first;

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
                        CurrencyInputFormatter(
                          locale: AppSettingsScope.of(context).currencyLocale,
                          symbol: AppSettingsScope.of(context).currencySymbol,
                        ),
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
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions(tokens).map((color) {
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
                        color: isSelected
                            ? tokens.textPrimary
                            : tokens.background.withValues(alpha: 0.0),
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

// Card de banco com edicao e visualizacao.
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

  // Desenha o card com saldo e acoes.
  @override
  Widget build(BuildContext context) {
    final format = AppSettingsScope.of(context).currencyFormatter();
    final tokens = AppThemeTokens.of(context);
    final ratio = totalBalance <= 0 ? 0.0 : (bank.balance / totalBalance).clamp(0.0, 1.0);
    final percent = (ratio * 100).toStringAsFixed(0);

    return Card(
      elevation: 0,
      color: tokens.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusMd)),
      child: InkWell(
        onTap: isEditing ? null : onEdit,
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(bank.colorValue),
                  borderRadius: BorderRadius.circular(AppLayout.radiusSm),
                ),
              ),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing)
                      TextField(
                        controller: nameController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Nome do banco',
                          hintStyle: TextStyle(color: tokens.textMuted),
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        bank.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    const SizedBox(height: AppLayout.spaceXs),
                    if (isEditing)
                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          CurrencyInputFormatter(
                            locale: AppSettingsScope.of(context).currencyLocale,
                            symbol: AppSettingsScope.of(context).currencySymbol,
                          ),
                        ],
                        maxLines: 1,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Saldo',
                          hintStyle: TextStyle(color: tokens.textMuted),
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(color: tokens.textSecondary),
                      )
                    else
                      Text(
                        format.format(bank.balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    const SizedBox(height: AppLayout.spaceSm),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: tokens.surfaceStrong,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(bank.colorValue)),
                    ),
                    const SizedBox(height: AppLayout.spaceXs),
                    Text(
                      '$percent% do total',
                      style: TextStyle(color: tokens.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppLayout.spaceSm),
              SizedBox(
                width: 40,
                  child: isEditing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: onSave,
                              icon: Icon(Icons.check, color: tokens.textSecondary),
                            ),
                            IconButton(
                              onPressed: onCancel,
                              icon: Icon(Icons.close, color: tokens.textSecondary),
                            ),
                          ],
                        )
                      : IconButton(
                          onPressed: onRemove,
                          icon: Icon(Icons.delete_outline, color: tokens.textSecondary),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card de acao para adicionar banco.
class _AddBankCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBankCard({required this.onTap});

  // Renderiza o botao de adicionar.
  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.radiusMd),
      child: Ink(
        height: AppLayout.controlHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLayout.radiusMd),
          border: Border.all(color: tokens.borderStrong),
          color: tokens.surfaceAlt,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: tokens.textSecondary),
              const SizedBox(width: AppLayout.spaceSm),
              Text('Adicionar banco', style: TextStyle(color: tokens.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// Card com grafico de distribuicao.
class _PieCard extends StatelessWidget {
  final List<BankAccount> banks;
  final double total;
  final NumberFormat formatter;

  const _PieCard({
    required this.banks,
    required this.total,
    required this.formatter,
  });

  // Desenha o grafico de pizza.
  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceLgTight),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Distribuicao por banco',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                formatter.format(total),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _PieChartPainter(
                  banks: banks,
                  total: total,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter do grafico de pizza.
class _PieChartPainter extends CustomPainter {
  final List<BankAccount> banks;
  final double total;

  _PieChartPainter({
    required this.banks,
    required this.total,
  });

  // Pinta os setores do grafico.
  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) {
      return;
    }
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var startAngle = -math.pi / 2;
    for (final bank in banks) {
      if (bank.balance <= 0) {
        continue;
      }
      final sweep = (bank.balance / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color(bank.colorValue);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

  }

  // Repaint quando os dados mudam.
  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.banks != banks || oldDelegate.total != total;
  }
}

// Informacao visual do status de saldo.
class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.color,
  });
}

// Modos de ordenacao da carteira.
enum _SortMode {
  balanceDesc,
  balanceAsc,
  nameAsc,
}
