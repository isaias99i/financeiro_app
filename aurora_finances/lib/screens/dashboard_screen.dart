import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../data/carteira_store.dart';
import '../data/menu_store.dart';
import '../data/receitas_store.dart';
import '../widgets/carteira_widget.dart';
import '../widgets/resumo_financeiro_widget.dart';
import '../widgets/aurora_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  final double reserva;

  const DashboardScreen({super.key, this.reserva = 0.0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MenuStore _menuStore;
  late final ReceitasStore _receitasStore;
  late final DespesasStore _despesasStore;
  late final CarteiraStore _carteiraStore;
  DashboardPeriod _period = DashboardPeriod.month;

  @override
  void initState() {
    super.initState();
    _menuStore = MenuStore();
    _receitasStore = ReceitasStore();
    _despesasStore = DespesasStore();
    _carteiraStore = CarteiraStore();
    _receitasStore.load();
    _despesasStore.load();
    _carteiraStore.load();
  }

  @override
  void dispose() {
    _menuStore.dispose();
    _receitasStore.dispose();
    _despesasStore.dispose();
    _carteiraStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_receitasStore, _despesasStore, _carteiraStore]),
        builder: (context, _) {
          final now = DateTime.now();
          final receitasMes = _receitasStore.totalForMonth(now);
          final despesasMes = _despesasStore.totalForMonth(now);
          final double saldoMensal = receitasMes - despesasMes;
          final double saldoAposReserva = saldoMensal - widget.reserva;
          final double saldoAtual = _carteiraStore.totalBalance;
          final int periodMonths = _period.months;
          final double receitasPeriodo =
              _sumForPeriod(now, periodMonths, _receitasStore.totalForMonth);
          final double despesasPeriodo =
              _sumForPeriod(now, periodMonths, _despesasStore.totalForMonth);
          final double saldoPeriodo = receitasPeriodo - despesasPeriodo;
          final double saldoMesAnterior =
              _receitasStore.totalForMonth(_monthOffset(now, 1)) -
                  _despesasStore.totalForMonth(_monthOffset(now, 1));
          final _Variation variation = _buildVariation(
            saldoMensal,
            saldoMesAnterior,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroSaldoCard(
                  saldoAtual: saldoAtual,
                  saldoPeriodo: saldoPeriodo,
                  periodLabel: _period.label,
                  variation: variation,
                ),
                const SizedBox(height: 12),
                _PeriodChips(
                  selected: _period,
                  onSelected: (value) => setState(() => _period = value),
                ),
                const SizedBox(height: 16),
                ResumoFinanceiroWidget(
                  menuStore: _menuStore,
                  receitasStore: _receitasStore,
                  despesasStore: _despesasStore,
                  receitas: receitasMes,
                  despesas: despesasMes,
                  saldoMensal: saldoMensal,
                  saldoAposReserva: saldoAposReserva,
                  saldoAtual: saldoAtual,
                  segurancaAno: despesasMes * 12,
                ),
                const SizedBox(height: 20),
                CarteiraWidget(
                  store: _carteiraStore,
                  expectedBalance: saldoMensal,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  DateTime _monthOffset(DateTime base, int offset) {
    return DateTime(base.year, base.month - offset, 1);
  }

  double _sumForPeriod(
    DateTime base,
    int months,
    double Function(DateTime month) resolver,
  ) {
    var total = 0.0;
    for (var i = 0; i < months; i++) {
      total += resolver(_monthOffset(base, i));
    }
    return total;
  }

  _Variation _buildVariation(double current, double previous) {
    if (previous.abs() < 0.01) {
      return const _Variation.unavailable();
    }
    final diff = current - previous;
    final percent = (diff / previous.abs()) * 100.0;
    return _Variation.available(diff: diff, percent: percent);
  }
}

enum DashboardPeriod {
  month(1, 'Mes atual'),
  quarter(3, 'Ultimos 3 meses'),
  year(12, 'Ultimos 12 meses');

  const DashboardPeriod(this.months, this.label);

  final int months;
  final String label;
}

class _PeriodChips extends StatelessWidget {
  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onSelected;

  const _PeriodChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DashboardPeriod.values.map((period) {
        return _PeriodChip(
          label: period.label,
          isSelected: period == selected,
          onTap: () => onSelected(period),
        );
      }).toList(),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1C8EC9).withValues(alpha: 0.5),
        const Color(0xFF1FAF86).withValues(alpha: 0.35),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _HeroSaldoCard extends StatelessWidget {
  final double saldoAtual;
  final double saldoPeriodo;
  final String periodLabel;
  final _Variation variation;

  const _HeroSaldoCard({
    required this.saldoAtual,
    required this.saldoPeriodo,
    required this.periodLabel,
    required this.variation,
  });

  @override
  Widget build(BuildContext context) {
    final moneyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final variationColor = variation.isPositive
        ? const Color(0xFF1FAF86)
        : const Color(0xFFE36A4F);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C8EC9).withValues(alpha: 0.35),
            const Color(0xFF1FAF86).withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Saldo atual',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              if (variation.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: variationColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    variation.label,
                    style: TextStyle(
                      color: variationColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            moneyFormatter.format(saldoAtual),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                periodLabel,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const Spacer(),
              Text(
                moneyFormatter.format(saldoPeriodo),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Variation {
  final double diff;
  final double percent;
  final bool isAvailable;

  const _Variation._({
    required this.diff,
    required this.percent,
    required this.isAvailable,
  });

  const _Variation.unavailable() : this._(diff: 0, percent: 0, isAvailable: false);

  const _Variation.available({required this.diff, required this.percent})
      : isAvailable = true;

  bool get isPositive => diff >= 0;

  String get label {
    if (!isAvailable) return '--';
    final sign = diff >= 0 ? '+' : '-';
    return '$sign${percent.abs().toStringAsFixed(1)}%';
  }
}
