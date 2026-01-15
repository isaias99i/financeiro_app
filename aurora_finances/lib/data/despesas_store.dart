import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/month_key.dart';

class DespesasStore extends ChangeNotifier {
  static const _groupsKey = 'despesas_groups';
  static const _valuesKey = 'despesas_values';

  final List<ExpenseGroup> _groups = [];
  final Map<String, double> _valuesByCell = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  UnmodifiableListView<ExpenseGroup> get groups => UnmodifiableListView(_groups);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);
    final valuesJson = prefs.getString(_valuesKey);

    _groups.clear();
    if (groupsJson != null) {
      final decoded = jsonDecode(groupsJson) as List<dynamic>;
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        _groups.add(ExpenseGroup.fromJson(map));
      }
    }

    _valuesByCell.clear();
    if (valuesJson != null) {
      final decoded = jsonDecode(valuesJson) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        if (value is num) {
          _valuesByCell[key] = value.toDouble();
        }
      });
    }

    _isLoaded = true;
    notifyListeners();
  }

  void addGroup(String title) {
    _groups.add(ExpenseGroup(id: _newId(), title: title, columns: []));
    _persist();
    notifyListeners();
  }

  void updateGroup(ExpenseGroup group, String title) {
    group.title = title;
    _persist();
    notifyListeners();
  }

  void removeGroup(ExpenseGroup group) {
    _groups.removeWhere((item) => item.id == group.id);
    _persist();
    notifyListeners();
  }

  void addColumn(ExpenseGroup group, String title) {
    group.columns.add(ExpenseColumn(id: _newId(), title: title));
    _persist();
    notifyListeners();
  }

  void updateColumn(ExpenseGroup group, ExpenseColumn column, String title) {
    column.title = title;
    _persist();
    notifyListeners();
  }

  void removeColumn(ExpenseGroup group, ExpenseColumn column) {
    group.columns.removeWhere((item) => item.id == column.id);
    _valuesByCell.removeWhere((key, _) => key.endsWith('|${column.id}'));
    _persist();
    notifyListeners();
  }

  double valueForCell(DateTime month, ExpenseColumn column) {
    return _valuesByCell[_cellKey(month, column.id)] ?? 0.0;
  }

  void setValueForCell(DateTime month, ExpenseColumn column, double value) {
    _valuesByCell[_cellKey(month, column.id)] = value;
    _persist();
    notifyListeners();
  }

  double totalForMonth(DateTime month) {
    var total = 0.0;
    for (final group in _groups) {
      for (final column in group.columns) {
        total += valueForCell(month, column);
      }
    }
    return total;
  }

  void _persist() {
    if (!_isLoaded) return;
    SharedPreferences.getInstance().then((prefs) {
      final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
      final valuesJson = jsonEncode(_valuesByCell);
      prefs.setString(_groupsKey, groupsJson);
      prefs.setString(_valuesKey, valuesJson);
    });
  }

  static String _cellKey(DateTime month, String columnId) {
    return '${monthKey(month)}|$columnId';
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class ExpenseGroup {
  ExpenseGroup({
    required this.id,
    required this.title,
    required this.columns,
  });

  final String id;
  String title;
  final List<ExpenseColumn> columns;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'columns': columns.map((c) => c.toJson()).toList(),
      };

  factory ExpenseGroup.fromJson(Map<String, dynamic> json) {
    final columnsJson = json['columns'] as List<dynamic>? ?? [];
    return ExpenseGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      columns: columnsJson
          .map((item) => ExpenseColumn.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExpenseColumn {
  ExpenseColumn({required this.id, required this.title});

  final String id;
  String title;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };

  factory ExpenseColumn.fromJson(Map<String, dynamic> json) {
    return ExpenseColumn(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }
}
