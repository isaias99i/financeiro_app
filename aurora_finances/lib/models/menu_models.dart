enum MenuSectionType { receitas, despesas }

enum MenuItemKind { metric, custom }

enum MenuMetric {
  receitas,
  despesas,
  saldoMensal,
  saldoAposReserva,
  saldoAtual,
  segurancaAno,
}

String menuMetricTitle(MenuMetric metric) {
  switch (metric) {
    case MenuMetric.receitas:
      return 'Receitas';
    case MenuMetric.despesas:
      return 'Despesas';
    case MenuMetric.saldoMensal:
      return 'Saldo Mensal';
    case MenuMetric.saldoAposReserva:
      return 'Saldo Apos Reserva';
    case MenuMetric.saldoAtual:
      return 'Atual';
    case MenuMetric.segurancaAno:
      return 'Seguranca Ano';
  }
}

class MenuItemConfig {
  final String id;
  final MenuItemKind kind;
  final MenuMetric? metric;
  final String title;
  final String? customValue;

  MenuItemConfig.metric({
    required this.id,
    required this.metric,
    required this.title,
  })  : kind = MenuItemKind.metric,
        customValue = null;

  MenuItemConfig.custom({
    required this.id,
    required this.title,
    required this.customValue,
  })  : kind = MenuItemKind.custom,
        metric = null;
}

class MenuSectionConfig {
  final MenuSectionType type;
  final String title;
  final List<MenuItemConfig> items;

  MenuSectionConfig({
    required this.type,
    required this.title,
    required this.items,
  });
}
