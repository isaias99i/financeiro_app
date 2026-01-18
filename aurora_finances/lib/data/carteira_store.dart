import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/carteira_models.dart';

class CarteiraStore extends ChangeNotifier {
  CarteiraStore({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  final List<BankAccount> _banks = [];
  bool _isLoaded = false;
  int _idCounter = 0;

  bool get isLoaded => _isLoaded;

  UnmodifiableListView<BankAccount> get banks => UnmodifiableListView(_banks);

  double get totalBalance =>
      _banks.fold(0.0, (total, bank) => total + bank.balance);

  void addBank(BankAccount bank) {
    _banks.add(bank);
    _persist();
    notifyListeners();
  }

  void updateBank(String id, BankAccount updated) {
    final index = _banks.indexWhere((bank) => bank.id == id);
    if (index == -1) {
      return;
    }
    _banks[index] = updated;
    _persist();
    notifyListeners();
  }

  void removeBank(String id) {
    _banks.removeWhere((bank) => bank.id == id);
    _persist();
    notifyListeners();
  }

  String nextId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  Future<void> load() async {
    _banks.clear();
    final doc = await _docRef().get();
    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      final banksRaw = data['banks'] as List<dynamic>? ?? [];
      _banks.addAll(
        banksRaw
            .map((item) => BankAccount.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    _isLoaded = true;
    notifyListeners();
  }

  void _persist() {
    if (!_isLoaded) {
      return;
    }
    final payload = {
      'banks': _banks.map((bank) => bank.toJson()).toList(),
    };
    _docRef().set(payload);
  }

  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('carteira')
        .doc('data');
  }
}
