// Tipos de secao do menu.
enum MenuSectionType { receitas, despesas }

// Tipos de item do menu.
enum MenuItemKind { metric, custom }

// Metricas disponiveis no resumo.
enum MenuMetric {
  receitas,
  despesas,
  saldoMensal,
  saldoAposReserva,
  saldoAtual,
  segurancaAno,
}

// Titulo exibido para cada metrica.
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

// Chave de identificacao para metrico custom.
String menuMetricKey(MenuMetric metric) {
  return 'menuMetric.${metric.name}';
}

// Configuracao de item do menu.
class MenuItemConfig {
  final String id;
  final MenuItemKind kind;
  final MenuMetric? metric;
  final String title;
  final String? customValue;

  // Item baseado em metrica fixa.
  MenuItemConfig.metric({
    required this.id,
    required this.metric,
    required this.title,
  })  : kind = MenuItemKind.metric,
        customValue = null;

  // Item com valor customizado pelo usuario.
  MenuItemConfig.custom({
    required this.id,
    required this.title,
    required this.customValue,
  })  : kind = MenuItemKind.custom,
        metric = null;
}

// Configuracao de uma secao do menu.
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

// Entrada pronta para exibicao no menu.
class MenuItemEntry {
  final MenuSectionType type;
  final MenuItemConfig item;

  const MenuItemEntry({required this.type, required this.item});
}
