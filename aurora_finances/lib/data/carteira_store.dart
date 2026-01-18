import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/carteira_models.dart';

// Store da carteira (contas bancarias) do usuario.
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

  // Indica se os dados foram carregados.
  bool get isLoaded => _isLoaded;

  // Lista imutavel de contas.
  UnmodifiableListView<BankAccount> get banks => UnmodifiableListView(_banks);

  // Soma do saldo total das contas.
  double get totalBalance =>
      _banks.fold(0.0, (total, bank) => total + bank.balance);

  // Adiciona uma conta bancaria.
  void addBank(BankAccount bank) {
    _banks.add(bank);
    _persist();
    notifyListeners();
  }

  // Atualiza uma conta bancaria.
  void updateBank(String id, BankAccount updated) {
    final index = _banks.indexWhere((bank) => bank.id == id);
    if (index == -1) {
      return;
    }
    _banks[index] = updated;
    _persist();
    notifyListeners();
  }

  // Remove uma conta bancaria.
  void removeBank(String id) {
    _banks.removeWhere((bank) => bank.id == id);
    _persist();
    notifyListeners();
  }

  // Gera id unico para novas contas.
  String nextId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  // Carrega contas do Firestore.
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

  // Persiste contas no Firestore.
  void _persist() {
    if (!_isLoaded) {
      return;
    }
    final payload = {
      'banks': _banks.map((bank) => bank.toJson()).toList(),
    };
    _docRef().set(payload);
  }

  // Referencia ao documento da carteira do usuario.
  DocumentReference<Map<String, dynamic>> _docRef() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('carteira')
        .doc('data');
  }
}
