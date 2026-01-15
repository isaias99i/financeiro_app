import '../models/dynamic_table_models.dart';

List<DynamicRow> generateDataDespesasUntil2040() {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return List<DynamicRow>.generate(months.length, (index) {
    final fixosNaoAlteraveis = 1200.0 + (index * 5);
    final fixosAlteraveis = 600.0 + (index * 3);
    final variaveis = 400.0 + (index * 4);
    final resultado = -(fixosNaoAlteraveis + fixosAlteraveis + variaveis);

    return DynamicRow(
      month: months[index],
      values: DynamicValue.single({
        'Gastos Fixos Nao Alteraveis': fixosNaoAlteraveis,
        'Gastos Fixos Alteraveis': fixosAlteraveis,
        'Gastos Variados': variaveis,
        'Resultado': resultado,
      }),
    );
  });
}
