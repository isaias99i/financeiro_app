import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/carteira_models.dart';

class CarteiraStore extends ChangeNotifier {
  static const _banksKey = 'carteira_bancos';

  final List<BankAccount> _banks = [];
  bool _isLoaded = false;
  int _idCounter = 0;

  bool get isLoaded => _isLoaded;

  UnmodifiableListView<BankAccount> get banks => UnmodifiableListView(_banks);

  double get totalBalance =>
      _banks.fold(0.0, (sum, bank) => sum + bank.balance);

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
    final prefs = await SharedPreferences.getInstance();
    final banksJson = prefs.getString(_banksKey);

    _banks.clear();
    if (banksJson != null) {
      final decoded = jsonDecode(banksJson) as List<dynamic>;
      _banks.addAll(
        decoded
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
    SharedPreferences.getInstance().then((prefs) {
      final banksJson = jsonEncode(_banks.map((bank) => bank.toJson()).toList());
      prefs.setString(_banksKey, banksJson);
    });
  }
}
