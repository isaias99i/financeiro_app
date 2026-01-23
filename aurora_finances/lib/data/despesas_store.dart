import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/despesas_models.dart';
import '../utils/month_key.dart';

// Store de despesas por usuario.
class ExpensesStore extends ChangeNotifier {
  ExpensesStore({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  final List<ExpenseCategory> _categories = [];
  final List<ExpenseEntry> _entries = [];
  final Map<String, double> _fixedValues = {};
  int _idCounter = 0;
  bool _isLoaded = false;

  // Indica se os dados foram carregados.
  bool get isLoaded => _isLoaded;
  // Lista imutavel de categorias.
  UnmodifiableListView<ExpenseCategory> get categories =>
      UnmodifiableListView(_categories);
  // Lista imutavel de lancamentos.
  UnmodifiableListView<ExpenseEntry> get entries =>
      UnmodifiableListView(_entries);

  // Mantem chaves legadas para compatibilidade com dados persistidos.
  static const String _legacyCategoryListKey = 'groups';
  static const String _legacyEntryListKey = 'entries';
  static const String _legacyFixedValuesKey = 'simpleValues';

  // Carrega despesas do Firestore.
  Future<void> load() async {
    final doc = await _docRef().get();
    _categories.clear();
    _entries.clear();
    _fixedValues.clear();
    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      final categoriesRaw = data[_legacyCategoryListKey] as List<dynamic>? ?? [];
      for (final item in categoriesRaw) {
        final map = item as Map<String, dynamic>;
        _categories.add(ExpenseCategory.fromJson(map));
      }
      final entriesRaw = data[_legacyEntryListKey] as List<dynamic>? ?? [];
      _entries.addAll(
        entriesRaw
            .map((item) => ExpenseEntry.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      final fixedValuesRaw =
          data[_legacyFixedValuesKey] as Map<String, dynamic>? ?? {};
      fixedValuesRaw.forEach((key, value) {
        if (value is num) {
          _fixedValues[key] = value.toDouble();
        }
      });
    }

    _isLoaded = true;
    notifyListeners();
  }

  // Cria uma nova categoria de despesas.
  void addCategory(String title) {
    _categories.add(
      ExpenseCategory(id: _nextId(), title: title, subcategories: []),
    );
    _persist();
    notifyListeners();
  }

  // Atualiza o nome de uma categoria.
  void updateCategory(ExpenseCategory category, String title) {
    category.title = title;
    _persist();
    notifyListeners();
  }

  // Remove uma categoria e seus dados.
  void removeCategory(ExpenseCategory category) {
    _categories.removeWhere((item) => item.id == category.id);
    _persist();
    notifyListeners();
  }

  // Reordena categorias.
  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);
    _persist();
    notifyListeners();
  }

  // Adiciona subcategoria dentro de uma categoria.
  void addSubcategory(
    ExpenseCategory category,
    String title, {
    required bool requiresEntries,
  }) {
    category.subcategories.add(
      ExpenseSubcategory(
        id: _nextId(),
        title: title,
        requiresEntries: requiresEntries,
      ),
    );
    _persist();
    notifyListeners();
  }

  // Atualiza o nome da subcategoria.
  void updateSubcategory(
    ExpenseCategory category,
    ExpenseSubcategory subcategory,
    String title,
  ) {
    subcategory.title = title;
    _persist();
    notifyListeners();
  }

  // Remove subcategoria e itens associados.
  void removeSubcategory(
    ExpenseCategory category,
    ExpenseSubcategory subcategory,
  ) {
    category.subcategories.removeWhere((item) => item.id == subcategory.id);
    _entries.removeWhere((entry) => entry.subcategoryId == subcategory.id);
    _fixedValues.removeWhere((key, _) => key.endsWith('|${subcategory.id}'));
    _persist();
    notifyListeners();
  }

  // Reordena subcategorias dentro de uma categoria.
  void reorderSubcategories(
    ExpenseCategory category,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final subcategory = category.subcategories.removeAt(oldIndex);
    category.subcategories.insert(newIndex, subcategory);
    _persist();
    notifyListeners();
  }

  // Soma total do mes.
  double totalForMonth(DateTime month) {
    var total = 0.0;
    for (final category in _categories) {
      for (final subcategory in category.subcategories) {
        total += totalForSubcategory(month, subcategory);
      }
    }
    return total;
  }

  // Soma total de uma categoria no mes.
  double totalForCategory(DateTime month, ExpenseCategory category) {
    var total = 0.0;
    for (final subcategory in category.subcategories) {
      total += totalForSubcategory(month, subcategory);
    }
    return total;
  }

  // Soma total de uma subcategoria no mes.
  double totalForSubcategory(DateTime month, ExpenseSubcategory subcategory) {
    if (!subcategory.requiresEntries) {
      return valueForSubcategory(month, subcategory);
    }
    var total = 0.0;
    for (final entry in _entries) {
      if (entry.subcategoryId == subcategory.id &&
          isSameMonth(entry.date, month)) {
        total += entry.amount;
      }
    }
    return total;
  }

  // Conta lancamentos de uma subcategoria no mes.
  int countForSubcategory(DateTime month, ExpenseSubcategory subcategory) {
    if (!subcategory.requiresEntries) {
      return 0;
    }
    var count = 0;
    for (final entry in _entries) {
      if (entry.subcategoryId == subcategory.id &&
          isSameMonth(entry.date, month)) {
        count += 1;
      }
    }
    return count;
  }

  // Retorna lancamentos de uma subcategoria.
  List<ExpenseEntry> entriesForSubcategory(ExpenseSubcategory subcategory) {
    return _entries
        .where((entry) => entry.subcategoryId == subcategory.id)
        .toList();
  }

  // Retorna valor fixo para subcategoria sem lancamentos.
  double valueForSubcategory(DateTime month, ExpenseSubcategory subcategory) {
    return _fixedValues[_fixedValueKey(month, subcategory.id)] ?? 0.0;
  }

  // Define valor fixo para subcategoria sem lancamentos.
  void setValueForSubcategory(
    DateTime month,
    ExpenseSubcategory subcategory,
    double value,
  ) {
    _fixedValues[_fixedValueKey(month, subcategory.id)] = value;
    _persist();
    notifyListeners();
  }

  // Aplica valor fixo em varios meses.
  void setFixedValueFromMonth(
    DateTime start,
    DateTime end,
    ExpenseSubcategory subcategory,
    double value,
  ) {
    var current = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!current.isAfter(last)) {
      _fixedValues[_fixedValueKey(current, subcategory.id)] = value;
      current = DateTime(current.year, current.month + 1, 1);
    }
    _persist();
    notifyListeners();
  }

  // Adiciona um novo lancamento.
  void addEntry(ExpenseEntry entry) {
    _entries.add(entry);
    _persist();
    notifyListeners();
  }

  // Atualiza um lancamento existente.
  void updateEntry(String id, ExpenseEntry updated) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      return;
    }
    _entries[index] = updated;
    _persist();
    notifyListeners();
  }

  // Remove um lancamento pelo id.
  void removeEntry(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    _persist();
    notifyListeners();
  }

  // Persiste categorias, lancamentos e valores fixos.
  void _persist() {
    if (!_isLoaded) return;
    final payload = {
      _legacyCategoryListKey: _categories.map((c) => c.toJson()).toList(),
      _legacyEntryListKey: _entries.map((entry) => entry.toJson()).toList(),
      _legacyFixedValuesKey: _fixedValues,
    };
    _docRef().set(payload);
  }

  // Monta chave unica para valores fixos.
  static String _fixedValueKey(DateTime month, String subcategoryId) {
    return '${monthKey(month)}|$subcategoryId';
  }

  // Gera id publico para novos lancamentos.
  String nextId() => _nextId();

  // Gera id interno unico.
  String _nextId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  // Referencia ao documento de despesas do usuario.
  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('despesas')
        .doc('data');
  }
}
