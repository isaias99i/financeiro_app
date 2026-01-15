import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/despesas_store.dart';
import '../data/menu_store.dart';
import '../data/receitas_store.dart';
import '../widgets/carteira_widget.dart';
import '../widgets/resumo_financeiro_widget.dart';
import '../widgets/aurora_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  final double receitas = 0.00;
  final double despesas = 0.0;
  final double reserva = 0.00;

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MenuStore _menuStore;
  late final ReceitasStore _receitasStore;
  late final DespesasStore _despesasStore;

  @override
  void initState() {
    super.initState();
    _menuStore = MenuStore();
    _receitasStore = ReceitasStore();
    _despesasStore = DespesasStore();
    _receitasStore.load();
    _despesasStore.load();
  }

  @override
  void dispose() {
    _menuStore.dispose();
    _receitasStore.dispose();
    _despesasStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_receitasStore, _despesasStore]),
        builder: (context, _) {
          final now = DateTime.now();
          final currentMonthLabel = DateFormat('MM/yyyy').format(now);
          final receitasMes = _receitasStore.totalForMonth(now);
          final despesasMes = _despesasStore.totalForMonth(now);
          final double saldoMensal = receitasMes - despesasMes;
          final double saldoAposReserva = saldoMensal - widget.reserva;

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
                  saldoAtual: 0,
                  segurancaAno: despesasMes * 12,
                ),
                const SizedBox(height: 20),
                const CarteiraWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
