import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/despesas_models.dart';
import '../utils/month_key.dart';


class DespesasStore extends ChangeNotifier {
  static const _groupsKey = 'despesas_groups';
  static const _entriesKey = 'despesas_entries';
  static const _legacyValuesKey = 'despesas_values';
  static const _simpleValuesKey = 'despesas_simple_values';

  final List<ExpenseGroup> _groups = [];
  final List<ExpenseEntry> _entries = [];
  final Map<String, double> _simpleValues = {};
  int _idCounter = 0;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  UnmodifiableListView<ExpenseGroup> get groups => UnmodifiableListView(_groups);
  UnmodifiableListView<ExpenseEntry> get entries => UnmodifiableListView(_entries);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);
    final entriesJson = prefs.getString(_entriesKey);
    final legacyValuesJson = prefs.getString(_legacyValuesKey);
    final simpleValuesJson = prefs.getString(_simpleValuesKey);

    _groups.clear();
    if (groupsJson != null) {
      final decoded = jsonDecode(groupsJson) as List<dynamic>;
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        _groups.add(ExpenseGroup.fromJson(map));
      }
    }

    _entries.clear();
    if (entriesJson != null) {
      final decoded = jsonDecode(entriesJson) as List<dynamic>;
      _entries.addAll(
        decoded
            .map((item) => ExpenseEntry.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } else if (legacyValuesJson != null) {
      _migrateLegacyValues(legacyValuesJson);
    }

    _simpleValues.clear();
    if (simpleValuesJson != null) {
      final decoded = jsonDecode(simpleValuesJson) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        if (value is num) {
          _simpleValues[key] = value.toDouble();
        }
      });
    }

    _isLoaded = true;
    notifyListeners();
  }

  void addGroup(String title) {
    _groups.add(ExpenseGroup(id: _nextId(), title: title, columns: []));
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

  void addColumn(ExpenseGroup group, String title, {required bool requiresEntries}) {
    group.columns.add(
      ExpenseColumn(id: _nextId(), title: title, requiresEntries: requiresEntries),
    );
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
    _entries.removeWhere((entry) => entry.columnId == column.id);
    _simpleValues.removeWhere((key, _) => key.endsWith('|${column.id}'));
    _persist();
    notifyListeners();
  }

  double totalForMonth(DateTime month) {
    var total = 0.0;
    for (final group in _groups) {
      for (final column in group.columns) {
        total += totalForColumn(month, column);
      }
    }
    return total;
  }

  double totalForGroup(DateTime month, ExpenseGroup group) {
    var total = 0.0;
    for (final column in group.columns) {
      total += totalForColumn(month, column);
    }
    return total;
  }

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

  List<ExpenseEntry> entriesForColumn(ExpenseColumn column) {
    return _entries.where((entry) => entry.columnId == column.id).toList();
  }

  double valueForColumn(DateTime month, ExpenseColumn column) {
    return _simpleValues[_simpleKey(month, column.id)] ?? 0.0;
  }

  void setValueForColumn(DateTime month, ExpenseColumn column, double value) {
    _simpleValues[_simpleKey(month, column.id)] = value;
    _persist();
    notifyListeners();
  }

  void addEntry(ExpenseEntry entry) {
    _entries.add(entry);
    _persist();
    notifyListeners();
  }

  void updateEntry(String id, ExpenseEntry updated) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      return;
    }
    _entries[index] = updated;
    _persist();
    notifyListeners();
  }

  void removeEntry(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    _persist();
    notifyListeners();
  }

  void _persist() {
    if (!_isLoaded) return;
    SharedPreferences.getInstance().then((prefs) {
      final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
      prefs.setString(_groupsKey, groupsJson);
      final entriesJson = jsonEncode(_entries.map((entry) => entry.toJson()).toList());
      prefs.setString(_entriesKey, entriesJson);
      final simpleValuesJson = jsonEncode(_simpleValues);
      prefs.setString(_simpleValuesKey, simpleValuesJson);
    });
  }

  static String _simpleKey(DateTime month, String columnId) {
    return '${monthKey(month)}|$columnId';
  }

  String nextId() => _nextId();

  String _nextId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  void _migrateLegacyValues(String legacyValuesJson) {
    final decoded = jsonDecode(legacyValuesJson) as Map<String, dynamic>;
    decoded.forEach((key, value) {
      if (value is! num) {
        return;
      }
      final parts = key.split('|');
      if (parts.length != 2) {
        return;
      }
      final month = parseMonthKey(parts[0]);
      if (month == null) {
        return;
      }
      final amount = value.toDouble();
      if (amount <= 0) {
        return;
      }
      _entries.add(
        ExpenseEntry(
          id: _nextId(),
          columnId: parts[1],
          date: month,
          category: 'Migrado',
          reason: 'Saldo anterior',
          amount: amount,
        ),
      );
    });
  }

}
