import 'package:intl/intl.dart';

import '../widgets/DynamicTableWidget.dart'; // Para formatar as datas.

List<DynamicRow> generateDataDespesasUntil2040() {
  final now = DateTime.now(); // Data atual.
  const endYear = 2040;
  final List<DynamicRow> rows = [];

  // Formato para os meses (exemplo: "jan/2025").
  final monthFormatter = DateFormat("MMM/yyyy", "pt_BR");

  // Variáveis iniciais para preencher os valores (pode ser ajustado).
  double contribuicao = -670.0;
  double internet = -109.9;
  double fies = -218.16;
  double aluguelCasa = 0.0;
  double consorcioMoto = 0.0;
  double planoCabelo = -60.0;
  double recargaCelular = -29.99;
  double academia = 80.0;
  double aulaIngles = -3402.61;
  double ajudaMaeJSFibra = 0.0;
  double cartoesCredito = -2410.08;
  double emprestimos = -6820.74;
  double gastosDetalhados = -22649.27;
  double total = -33736.37;
  double gastosProx6Mesesnv2 = -3790.67;
  double gastosProx12MesesNv2 = -15000.0;
  double obrigacoes = -25000.0;

  // Armazene todas as variáveis em uma lista
  List<double> despesas = [
    contribuicao,
    internet,
    fies,
    aluguelCasa,
    consorcioMoto,
    planoCabelo,
    recargaCelular,
    academia,
    aulaIngles,
    ajudaMaeJSFibra,
    cartoesCredito,
    emprestimos,
    gastosDetalhados,
    total,
    gastosProx6Mesesnv2,
    gastosProx12MesesNv2,
    obrigacoes,
  ];
// Use a função reduce para somar todas as variáveis
  double somaTotal = despesas.reduce((value, element) => value + element);

  // Gerar meses do ano atual até 2040.
  for (int year = now.year; year <= endYear; year++) {
    for (int month = (year == now.year ? now.month : 1); month <= 12; month++) {
      final date = DateTime(year, month);

      // Adicionar uma linha para cada mês.
      rows.add(
        DynamicRow(
          month: monthFormatter.format(date).replaceAll('.', ''),
          values: DynamicValue.single(
            {
              'Contribuição': contribuicao,
              'JS Fibra 12/Mês': internet,
              'FIES': fies,
              'Aluguel de casa': aluguelCasa,
              'Consorcio Moto': consorcioMoto,
              'Plano Corte de Cabelo': planoCabelo,
              'Recarga Celular': recargaCelular,
              'Academia': academia,
              'Aulas Inglês': aulaIngles,
              'Ajuda Mãe Internet': ajudaMaeJSFibra,
              'Cartões de Credito': cartoesCredito,
              'Empréstimos': emprestimos,
              'Gastos Detalhados': gastosDetalhados,
              'Gastos Prox 6 meses': gastosProx6Mesesnv2,
              'Gastos Prox 12 meses': gastosProx12MesesNv2,
              'Obrigacoes': obrigacoes,
              'Total': somaTotal,
            },
          ),
        ),
      );

      // Opcional: Modificar os valores mês a mês (exemplo: incremento de salário anual).
      /*if (month == 12) {
        salario += 100.0; // Aumenta o salário anualmente.
      }*/
    }
  }

  return rows;
}
