import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CategoriesStore extends ChangeNotifier {
  CategoriesStore({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  final List<String> _categories = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  UnmodifiableListView<String> get categories =>
      UnmodifiableListView(_categories);

  Future<void> load() async {
    _categories.clear();
    final doc = await _docRef().get();
    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      final categoriesRaw = data['categories'] as List<dynamic>? ?? [];
      _categories.addAll(
        categoriesRaw
            .map((item) => item.toString())
            .where((name) => name.isNotEmpty),
      );
    }
    if (_categories.isEmpty) {
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
    final payload = {
      'categories': _categories,
    };
    _docRef().set(payload);
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

  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc('data');
  }
}
