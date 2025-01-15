import 'package:flutter/material.dart';

import '../widgets/DynamicTableWidget.dart';
import '../widgets/TableCellWidget.dart';

class DespesasScreen extends StatelessWidget {
  const DespesasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados da tabela
    final List<String> parentHeaders = [
      'Mês',
      'Gastos Fixos Não Alteráveis',
      'Gastos Fixos Alteráveis',
      'Gastos Variados',
      'Resultado',
    ];

    final List<int> parentSpans = [
      1, // "Mês" ocupa 1 coluna
      5, // "Gastos Fixos Não Alteráveis" ocupa 5 colunas
      5, // "Gastos Fixos Alteráveis" ocupa 5 colunas
      3, // "Gastos Variados" ocupa 3 colunas
      4, // "Resultado" ocupa 4 colunas
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
      ),
      body: Text('Em Construção')
    );
  }
}
