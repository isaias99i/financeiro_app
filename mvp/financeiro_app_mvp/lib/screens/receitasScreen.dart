import 'package:flutter/material.dart';
import '../widgets/DynamicTableWidget.dart';
import '../widgets/TableCellWidget.dart';

class ReceitasScreen extends StatelessWidget {
  const ReceitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colunas a exibir na tabela
    final List<String> headers = ['Mês', 'Salário', 'Extras', 'Total'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              // Cabeçalhos da tabela
              Row(
                children: headers.map((header) {
                  return GestureDetector(
                    onTap: () {
                      /*if (header == 'Extras') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExtrasScreen(),
                          ),
                        );
                      }*/
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Dados da tabela
              ...SharedData.receitas.map((row) {
                return Row(
                  children: [
                    TableCellWidget(
                      content: row.month,
                      width: 100,
                      textColor: Colors.black,
                    ),
                    ...headers.skip(1).map((header) {
                      final value = row.values[header] ?? '-';
                      return TableCellWidget(
                        content: value is double
                            ? 'R\$ ${value.toStringAsFixed(2)}'
                            : value.toString(),
                        width: 100,
                        textColor: value is double && value >= 0
                            ? Colors.black
                            : Colors.red,
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
