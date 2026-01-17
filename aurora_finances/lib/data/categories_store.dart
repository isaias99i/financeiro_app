import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesStore extends ChangeNotifier {
  static const _categoriesKey = 'expense_categories';

  final List<String> _categories = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  UnmodifiableListView<String> get categories =>
      UnmodifiableListView(_categories);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(_categoriesKey);

    _categories.clear();
    if (categoriesJson != null) {
      final decoded = jsonDecode(categoriesJson) as List<dynamic>;
      _categories.addAll(
        decoded.map((item) => item.toString()).where((name) => name.isNotEmpty),
      );
    } else {
      _categories.addAll(_defaultCategories());
    }

    _isLoaded = true;
    notifyListeners();
  }

  void addCategory(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return;
    }
    if (_containsCategory(normalized)) {
      return;
    }
    _categories.add(normalized);
    _persist();
    notifyListeners();
  }

  void updateCategory(String previous, String next) {
    final normalized = next.trim();
    if (normalized.isEmpty) {
      return;
    }
    if (previous != normalized && _containsCategory(normalized)) {
      return;
    }
    final index = _categories.indexWhere((item) => item == previous);
    if (index == -1) {
      return;
    }
    _categories[index] = normalized;
    _persist();
    notifyListeners();
  }

  void removeCategory(String name) {
    _categories.removeWhere((item) => item == name);
    _persist();
    notifyListeners();
  }

  bool _containsCategory(String name) {
    final target = name.toLowerCase();
    return _categories.any((item) => item.toLowerCase() == target);
  }

  void _persist() {
    if (!_isLoaded) return;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_categoriesKey, jsonEncode(_categories));
    });
  }

  List<String> _defaultCategories() {
    return const [
      'Alimentacao',
      'Refeição',
      'Transporte',
      'Saude',
      'Educacao',
      'Lazer',
      'Assinaturas',
      'Compras',
      'Equipamentos',
      'Tecnologia',
    ];
  }
}
