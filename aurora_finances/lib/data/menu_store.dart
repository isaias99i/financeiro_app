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
  final List<MenuItemEntry> _orderedItems = [];

  MenuStore() {
    for (final section in _sections) {
      _orderedItems.addAll(
        section.items.map((item) => MenuItemEntry(type: section.type, item: item)),
      );
    }
  }

  List<MenuSectionConfig> get sections => _sections;
  List<MenuItemEntry> get orderedItems => List.unmodifiable(_orderedItems);

  void reorderSections(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final section = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, section);
    notifyListeners();
  }

  void reorderItems(MenuSectionType type, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final section = _sectionFor(type);
    final item = section.items.removeAt(oldIndex);
    section.items.insert(newIndex, item);
    notifyListeners();
  }

  void reorderOrderedItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final entry = _orderedItems.removeAt(oldIndex);
    _orderedItems.insert(newIndex, entry);
    _syncSectionsFromOrder();
    notifyListeners();
  }

  void addMetricItem(MenuSectionType type, MenuMetric metric, {String? title}) {
    final section = _sectionFor(type);
    final item = MenuItemConfig.metric(
      id: _newId(),
      metric: metric,
      title: title?.trim().isNotEmpty == true ? title!.trim() : menuMetricTitle(metric),
    );
    section.items.add(item);
    _orderedItems.add(MenuItemEntry(type: type, item: item));
    notifyListeners();
  }

  void addCustomItem(MenuSectionType type, {required String title, required String value}) {
    final section = _sectionFor(type);
    final item = MenuItemConfig.custom(
      id: _newId(),
      title: title.trim(),
      customValue: value.trim(),
    );
    section.items.add(item);
    _orderedItems.add(MenuItemEntry(type: type, item: item));
    notifyListeners();
  }

  void removeItem(MenuSectionType type, String id) {
    final section = _sectionFor(type);
    section.items.removeWhere((item) => item.id == id);
    _orderedItems.removeWhere((entry) => entry.item.id == id);
    notifyListeners();
  }

  MenuSectionConfig _sectionFor(MenuSectionType type) {
    return _sections.firstWhere((section) => section.type == type);
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _syncSectionsFromOrder() {
    for (final section in _sections) {
      section.items
        ..clear()
        ..addAll(
          _orderedItems
              .where((entry) => entry.type == section.type)
              .map((entry) => entry.item),
        );
    }
  }
}
