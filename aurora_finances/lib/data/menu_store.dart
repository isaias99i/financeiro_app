import 'package:flutter/foundation.dart';

import '../models/menu_models.dart';

class MenuStore extends ChangeNotifier {
  final List<MenuSectionConfig> _sections = [
    MenuSectionConfig(
      type: MenuSectionType.receitas,
      title: 'Receitas',
      items: [
        MenuItemConfig.metric(
          id: _newId(),
          metric: MenuMetric.receitas,
          title: menuMetricTitle(MenuMetric.receitas),
        ),
        MenuItemConfig.metric(
          id: _newId(),
          metric: MenuMetric.saldoMensal,
          title: menuMetricTitle(MenuMetric.saldoMensal),
        ),
      ],
    ),
    MenuSectionConfig(
      type: MenuSectionType.despesas,
      title: 'Despesas',
      items: [
        MenuItemConfig.metric(
          id: _newId(),
          metric: MenuMetric.despesas,
          title: menuMetricTitle(MenuMetric.despesas),
        ),
        MenuItemConfig.metric(
          id: _newId(),
          metric: MenuMetric.saldoAposReserva,
          title: menuMetricTitle(MenuMetric.saldoAposReserva),
        ),
        MenuItemConfig.metric(
          id: _newId(),
          metric: MenuMetric.segurancaAno,
          title: menuMetricTitle(MenuMetric.segurancaAno),
        ),
        MenuItemConfig.metric(
          id: _newId(),
          metric: MenuMetric.saldoAtual,
          title: menuMetricTitle(MenuMetric.saldoAtual),
        ),
      ],
    ),
  ];

  List<MenuSectionConfig> get sections => _sections;

  void addMetricItem(MenuSectionType type, MenuMetric metric, {String? title}) {
    final section = _sectionFor(type);
    section.items.add(
      MenuItemConfig.metric(
        id: _newId(),
        metric: metric,
        title: title?.trim().isNotEmpty == true ? title!.trim() : menuMetricTitle(metric),
      ),
    );
    notifyListeners();
  }

  void addCustomItem(MenuSectionType type, {required String title, required String value}) {
    final section = _sectionFor(type);
    section.items.add(
      MenuItemConfig.custom(
        id: _newId(),
        title: title.trim(),
        customValue: value.trim(),
      ),
    );
    notifyListeners();
  }

  void removeItem(MenuSectionType type, String id) {
    final section = _sectionFor(type);
    section.items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  MenuSectionConfig _sectionFor(MenuSectionType type) {
    return _sections.firstWhere((section) => section.type == type);
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
