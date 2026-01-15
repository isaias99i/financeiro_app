import 'package:flutter/material.dart';

import '../models/dynamic_table_models.dart';

class DynamicTableWidget extends StatelessWidget {
  final List<DynamicRow> data;
  final List<String> columns; // Nomes das colunas a exibir

  const DynamicTableWidget({super.key, required this.data, required this.columns});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Mês')),
          ...columns.map((col) => DataColumn(label: Text(col))),
        ],
        rows: data.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(row.month)),
              ...columns.map((col) {
                final value = row.values[col] ?? '-'; // Valor padrão se não existir
                return DataCell(Text(value.toString()));
              }),
            ],
          );
        }).toList(),

      ),
    );
  }
}
