import 'package:intl/intl.dart';
import '../widgets/DynamicTableWidget.dart'; // Para formatar as datas.

List<DynamicRow> generateDataReceitasUntil2040() {
  final now = DateTime.now(); // Data atual.
  const endYear = 2040;
  final List<DynamicRow> rows = [];

  // Formato para os meses (exemplo: "jan/2025").
  final monthFormatter = DateFormat("MMM/yyyy", "pt_BR");

  // Variáveis iniciais para preencher os valores (pode ser ajustado).
  double salario = 3500.00;
  double extras = 0.0;

  // Gerar meses do ano atual até 2040.
  for (int year = now.year; year <= endYear; year++) {
    for (int month = (year == now.year ? now.month : 1); month <= 12; month++) {
      final date = DateTime(year, month);

      // Adicionar uma linha para cada mês.
      rows.add(DynamicRow(
        month: monthFormatter.format(date),
        values: DynamicValue.single({
          'Salário': salario,
          'Extras': extras,
          'Total': salario + extras,
        }),
      ));

      // Opcional: Modificar os valores mês a mês (exemplo: incremento de salário anual).
      /*if (month == 12) {
        salario += 100.0; // Aumenta o salário anualmente.
      }*/
    }
  }

  return rows;
}
