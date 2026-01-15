import '../models/dynamic_table_models.dart';

List<DynamicRow> generateDataReceitasUntil2040() {
  const baseSalary = 3000.0;
  final extrasByMonth = <double>[
    200.0,
    150.0,
    0.0,
    300.0,
    100.0,
    250.0,
    0.0,
    400.0,
    150.0,
    100.0,
    200.0,
    500.0,
  ];

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
    final extras = extrasByMonth[index];
    final total = baseSalary + extras;
    return DynamicRow(
      month: months[index],
      values: DynamicValue.single({
        'Salario': baseSalary,
        'Extras': extras,
        'Total': total,
      }),
    );
  });
}
