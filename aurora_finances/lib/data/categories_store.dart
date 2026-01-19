import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Store de categorias de despesas do usuario.
class CategoriesStore extends ChangeNotifier {
  CategoriesStore({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  final List<String> _categories = [];
  bool _isLoaded = false;

  // Indica se as categorias foram carregadas.
  bool get isLoaded => _isLoaded;
  // Lista imutavel de categorias.
  UnmodifiableListView<String> get categories =>
      UnmodifiableListView(_categories);

  // Carrega categorias do Firestore.
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

  // Adiciona nova categoria.
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

  // Atualiza o nome de uma categoria.
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

  // Remove uma categoria.
  void removeCategory(String name) {
    _categories.removeWhere((item) => item == name);
    _persist();
    notifyListeners();
  }

  // Verifica se a categoria ja existe.
  bool _containsCategory(String name) {
    final target = name.toLowerCase();
    return _categories.any((item) => item.toLowerCase() == target);
  }

  // Persiste categorias no Firestore.
  void _persist() {
    if (!_isLoaded) return;
    final payload = {
      'categories': _categories,
    };
    _docRef().set(payload);
  }

  // Lista padrao usada quando nao ha categorias salvas.
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
      'Tecnologia'      
    ];
  }

  // Referencia ao documento de categorias do usuario.
  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc('data');
  }
}
