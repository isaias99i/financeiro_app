import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/receitas_models.dart';
import '../utils/month_key.dart';

class ReceitasStore extends ChangeNotifier {
  ReceitasStore({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

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
        .fold(0.0, (total, entry) => total + entry.amount);
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
    final doc = await _docRef().get();
    _salaryByMonth.clear();
    _extras = [];
    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      final salaryRaw = data['salaryByMonth'] as Map<String, dynamic>? ?? {};
      salaryRaw.forEach((key, value) {
        final numVal = value is num ? value.toDouble() : 0.0;
        _salaryByMonth[key] = numVal;
      });
      final extrasRaw = data['extras'] as List<dynamic>? ?? [];
      _extras = extrasRaw.map((item) {
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
    final payload = {
      'salaryByMonth': _salaryByMonth,
      'extras': _extras
          .map((entry) => {
                'date': entry.date.millisecondsSinceEpoch,
                'amount': entry.amount,
                'note': entry.note,
              })
          .toList(),
    };
    _docRef().set(payload);
  }

  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('receitas')
        .doc('data');
  }
}
