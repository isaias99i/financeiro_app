import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/despesas_models.dart';
import '../utils/month_key.dart';


// Store de despesas por usuario.
class DespesasStore extends ChangeNotifier {
  DespesasStore({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  final List<ExpenseGroup> _groups = [];
  final List<ExpenseEntry> _entries = [];
  final Map<String, double> _simpleValues = {};
  int _idCounter = 0;
  bool _isLoaded = false;

  // Indica se os dados foram carregados.
  bool get isLoaded => _isLoaded;
  // Lista imutavel de grupos.
  UnmodifiableListView<ExpenseGroup> get groups => UnmodifiableListView(_groups);
  // Lista imutavel de lancamentos.
  UnmodifiableListView<ExpenseEntry> get entries => UnmodifiableListView(_entries);

  // Carrega despesas do Firestore.
  Future<void> load() async {
    final doc = await _docRef().get();
    _groups.clear();
    _entries.clear();
    _simpleValues.clear();
    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      final groupsRaw = data['groups'] as List<dynamic>? ?? [];
      for (final item in groupsRaw) {
        final map = item as Map<String, dynamic>;
        _groups.add(ExpenseGroup.fromJson(map));
      }
      final entriesRaw = data['entries'] as List<dynamic>? ?? [];
      _entries.addAll(
        entriesRaw
            .map((item) => ExpenseEntry.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      final simpleValuesRaw = data['simpleValues'] as Map<String, dynamic>? ?? {};
      simpleValuesRaw.forEach((key, value) {
        if (value is num) {
          _simpleValues[key] = value.toDouble();
        }
      });
    }

    _isLoaded = true;
    notifyListeners();
  }

  // Cria um novo grupo de despesas.
  void addGroup(String title) {
    _groups.add(ExpenseGroup(id: _nextId(), title: title, columns: []));
    _persist();
    notifyListeners();
  }

  // Atualiza o nome de um grupo.
  void updateGroup(ExpenseGroup group, String title) {
    group.title = title;
    _persist();
    notifyListeners();
  }

  // Remove um grupo e seus dados.
  void removeGroup(ExpenseGroup group) {
    _groups.removeWhere((item) => item.id == group.id);
    _persist();
    notifyListeners();
  }

  // Reordena categorias.
  void reorderGroups(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final group = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, group);
    _persist();
    notifyListeners();
  }

  // Adiciona coluna dentro de um grupo.
  void addColumn(ExpenseGroup group, String title, {required bool requiresEntries}) {
    group.columns.add(
      ExpenseColumn(id: _nextId(), title: title, requiresEntries: requiresEntries),
    );
    _persist();
    notifyListeners();
  }

  // Atualiza o nome da coluna.
  void updateColumn(ExpenseGroup group, ExpenseColumn column, String title) {
    column.title = title;
    _persist();
    notifyListeners();
  }

  // Remove coluna e itens associados.
  void removeColumn(ExpenseGroup group, ExpenseColumn column) {
    group.columns.removeWhere((item) => item.id == column.id);
    _entries.removeWhere((entry) => entry.columnId == column.id);
    _simpleValues.removeWhere((key, _) => key.endsWith('|${column.id}'));
    _persist();
    notifyListeners();
  }

  // Reordena subcategorias dentro de uma categoria.
  void reorderColumns(ExpenseGroup group, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final column = group.columns.removeAt(oldIndex);
    group.columns.insert(newIndex, column);
    _persist();
    notifyListeners();
  }

  // Soma total do mes.
  double totalForMonth(DateTime month) {
    var total = 0.0;
    for (final group in _groups) {
      for (final column in group.columns) {
        total += totalForColumn(month, column);
      }
    }
    return total;
  }

  // Soma total de um grupo no mes.
  double totalForGroup(DateTime month, ExpenseGroup group) {
    var total = 0.0;
    for (final column in group.columns) {
      total += totalForColumn(month, column);
    }
    return total;
  }

  // Soma total de uma coluna no mes.
  double totalForColumn(DateTime month, ExpenseColumn column) {
    if (!column.requiresEntries) {
      return valueForColumn(month, column);
    }
    var total = 0.0;
    for (final entry in _entries) {
      if (entry.columnId == column.id && isSameMonth(entry.date, month)) {
        total += entry.amount;
      }
    }
    return total;
  }

  // Conta lancamentos de uma coluna no mes.
  int countForColumn(DateTime month, ExpenseColumn column) {
    if (!column.requiresEntries) {
      return 0;
    }
    var count = 0;
    for (final entry in _entries) {
      if (entry.columnId == column.id && isSameMonth(entry.date, month)) {
        count += 1;
      }
    }
    return count;
  }

  // Retorna lancamentos de uma coluna.
  List<ExpenseEntry> entriesForColumn(ExpenseColumn column) {
    return _entries.where((entry) => entry.columnId == column.id).toList();
  }

  // Retorna valor simples para coluna fixa.
  double valueForColumn(DateTime month, ExpenseColumn column) {
    return _simpleValues[_simpleKey(month, column.id)] ?? 0.0;
  }

  // Define valor simples para coluna fixa.
  void setValueForColumn(DateTime month, ExpenseColumn column, double value) {
    _simpleValues[_simpleKey(month, column.id)] = value;
    _persist();
    notifyListeners();
  }

  // Aplica valor fixo em varios meses.
  void setFixedValueFromMonth(
    DateTime start,
    DateTime end,
    ExpenseColumn column,
    double value,
  ) {
    var current = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!current.isAfter(last)) {
      _simpleValues[_simpleKey(current, column.id)] = value;
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

  // Persiste grupos, lancamentos e valores fixos.
  void _persist() {
    if (!_isLoaded) return;
    final payload = {
      'groups': _groups.map((g) => g.toJson()).toList(),
      'entries': _entries.map((entry) => entry.toJson()).toList(),
      'simpleValues': _simpleValues,
    };
    _docRef().set(payload);
  }

  // Monta chave unica para valores fixos.
  static String _simpleKey(DateTime month, String columnId) {
    return '${monthKey(month)}|$columnId';
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
