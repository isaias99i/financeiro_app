class BankAccount {
  final String id;
  final String name;
  final double balance;
  final int colorValue;

  const BankAccount({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorValue,
  });

  BankAccount copyWith({
    String? name,
    double? balance,
    int? colorValue,
  }) {
    return BankAccount(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'colorValue': colorValue,
    };
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF1C8EC9,
    );
  }
}
