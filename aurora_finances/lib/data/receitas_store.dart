import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/receitas_models.dart';
import '../utils/month_key.dart';

class ReceitasStore extends ChangeNotifier {
  static const _salaryKey = 'receitas_salary_by_month';
  static const _extrasKey = 'receitas_extras';

  final Map<String, double> _salaryByMonth = {};
  List<ExtraEntry> _extras = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  double salaryForMonth(DateTime date) {
    return _salaryByMonth[monthKey(date)] ?? 0.0;
  }

  bool hasSalaryForMonth(DateTime date) {
    return _salaryByMonth.containsKey(monthKey(date));
  }

  void setSalaryForMonth(DateTime date, double value) {
    _salaryByMonth[monthKey(date)] = value;
    _persist();
    notifyListeners();
  }

  void setSalaryFromMonth(DateTime start, DateTime end, double value) {
    var current = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!current.isAfter(last)) {
      _salaryByMonth[monthKey(current)] = value;
      current = DateTime(current.year, current.month + 1, 1);
    }
    _persist();
    notifyListeners();
  }

  double extrasTotalForMonth(DateTime date) {
    final target = monthKey(date);
    return _extras
        .where((entry) => monthKey(entry.date) == target)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double totalForMonth(DateTime date) {
    return salaryForMonth(date) + extrasTotalForMonth(date);
  }

  UnmodifiableListView<ExtraEntry> get extras => UnmodifiableListView(_extras);

  void setExtras(List<ExtraEntry> entries) {
    _extras = List<ExtraEntry>.from(entries);
    _persist();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final salaryJson = prefs.getString(_salaryKey);
    final extrasJson = prefs.getString(_extrasKey);

    _salaryByMonth.clear();
    if (salaryJson != null) {
      final decoded = jsonDecode(salaryJson) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        final numVal = value is num ? value.toDouble() : 0.0;
        _salaryByMonth[key] = numVal;
      });
    }

    _extras = [];
    if (extrasJson != null) {
      final decoded = jsonDecode(extrasJson) as List<dynamic>;
      _extras = decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return ExtraEntry(
          date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
          amount: (map['amount'] as num).toDouble(),
          note: (map['note'] as String?) ?? '',
        );
      }).toList();
    }

    _isLoaded = true;
    notifyListeners();
  }

  void _persist() {
    if (!_isLoaded) {
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      final salaryJson = jsonEncode(_salaryByMonth);
      final extrasJson = jsonEncode(
        _extras
            .map((entry) => {
                  'date': entry.date.millisecondsSinceEpoch,
                  'amount': entry.amount,
                  'note': entry.note,
                })
            .toList(),
      );
      prefs.setString(_salaryKey, salaryJson);
      prefs.setString(_extrasKey, extrasJson);
    });
  }
}
