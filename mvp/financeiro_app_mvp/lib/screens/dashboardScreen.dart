import 'package:flutter/material.dart';
import '../widgets/CarteiraWidget.dart';
import '../widgets/ResumoFinanceiroWidget.dart';


class DashboardScreen extends StatelessWidget {
  final double receitas = 0.00; // Exemplo de receita
  final double despesas = 0.0; // Exemplo de despesa (negativo)
  final double reserva = 0.00;

  const DashboardScreen({super.key}); // Valor fixo da reserva anual para cálculo

  @override
  Widget build(BuildContext context) {
    final double saldoMensal = receitas + despesas; // Cálculo do saldo mensal
    final double saldoAposReserva = saldoMensal - reserva; // Cálculo do saldo após reserva

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResumoFinanceiroWidget(receitas: receitas, despesas: despesas, saldoMensal: saldoMensal, saldoAposReserva: saldoAposReserva,saldoAtual: 0, segurancaAno: despesas * 12,),
            const CarteiraWidget(),
          ],
        ),
      ),
    );
  }
}