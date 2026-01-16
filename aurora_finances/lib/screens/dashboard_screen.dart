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
          final currentMonthLabel = DateFormat('MMM/yyyy').format(now);
          final receitasMes = _receitasStore.totalForMonth(now);
          final despesasMes = _despesasStore.totalForMonth(now);
          final double saldoMensal = receitasMes - despesasMes;
          final double saldoAposReserva = saldoMensal - widget.reserva;
          final double saldoAtual = _carteiraStore.totalBalance;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Mes atual: $currentMonthLabel',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
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
                CarteiraWidget(store: _carteiraStore),
              ],
            ),
          );
        },
      ),
    );
  }
}
