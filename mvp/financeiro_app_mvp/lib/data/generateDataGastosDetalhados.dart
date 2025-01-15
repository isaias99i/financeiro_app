/*import 'package:financeiro/widgets/DynamicTableWidget.dart';
import 'package:intl/intl.dart';

List<DynamicRow> generateDataGastosDetalhados() {
  final now = DateTime.now();
  final startMonth = DateTime(2024, 11); // Início: Novembro de 2024
  final endMonth = DateTime(2025, 12);  // Fim: 1 ano à frente
  final List<DynamicRow> rows = [];

  final monthFormatter = DateFormat("MMM/yyyy", "pt_BR");

  // Dados predefinidos
  final predefinedData = {
    '11/2024': [
      {
        'Data': '24/11/2024',
        'Método': 'Banco Inter',
        'Motivo': 'Compras',
        'Gasto': '-R\$ 50,00',
      },
      {
        'Data': '28/11/2024',
        'Método': 'Banco Inter',
        'Motivo': 'Aposta Mega Sena',
        'Gasto': '-R\$ 5,00',
      },
      {
        'Data': '30/11/2024',
        'Método': 'Nubank',
        'Motivo': 'Bebidas Adiel e Fredson',
        'Gasto': '',
      },
    ],
    '12/2024': [
      {
        'Data': '03/12/2024',
        'Método': 'Itaú',
        'Motivo': 'IOF',
        'Gasto': '-R\$ 16,32',
      },
      {
        'Data': '04/12/2024',
        'Método': 'Nubank',
        'Motivo': 'Pão',
        'Gasto': 'R\$ 14,21',
      },
      {
        'Data': '04/12/2024',
        'Método': 'Nubank',
        'Motivo': 'Pão',
        'Gasto': 'R\$ 9,50',
      },
      {
        'Data': '05/12/2024',
        'Método': 'Nubank',
        'Motivo': 'Compras casa',
        'Gasto': 'R\$ 23,78',
      },
      {
        'Data': '06/12/2024',
        'Método': 'Santander',
        'Motivo': 'Compras Casa',
        'Gasto': 'R\$ 10,00',
      },
      // Adicione outros dados aqui...
    ],
  };

  // Iterar pelos meses de startMonth até endMonth
  DateTime currentMonth = startMonth;
  while (currentMonth.isBefore(endMonth)) {
    final monthKey = DateFormat("MM/yyyy").format(currentMonth);
    final monthDisplay = monthFormatter.format(currentMonth).replaceAll('.', '');

    // Obter os dados predefinidos para o mês, se existirem
    final monthData = predefinedData[monthKey];

    // Verificar se existem dados para o mês
    final dynamicValue = monthData != null && monthData.isNotEmpty
        ? DynamicValue.list(monthData)
        : DynamicValue.list([]);

    // Adicionar a linha ao resultado
    rows.add(DynamicRow(
      month: monthDisplay,
      values: dynamicValue,
    ));

    // Avançar para o próximo mês
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
  }

  return rows;
}
*/