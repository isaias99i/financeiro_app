// Agrupamento de colunas de despesas.
class ExpenseGroup {
  ExpenseGroup({
    required this.id,
    required this.title,
    required this.columns,
  });

  final String id;
  String title;
  final List<ExpenseColumn> columns;

  // Serializa o grupo para armazenamento.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'columns': columns.map((c) => c.toJson()).toList(),
      };

  // Reconstrui o grupo a partir do JSON.
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

// Coluna de despesas dentro de um grupo.
class ExpenseColumn {
  ExpenseColumn({
    required this.id,
    required this.title,
    required this.requiresEntries,
  });

  final String id;
  String title;
  bool requiresEntries;

  // Serializa a coluna.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'requiresEntries': requiresEntries,
      };

  // Reconstrui a coluna a partir do JSON.
  factory ExpenseColumn.fromJson(Map<String, dynamic> json) {
    return ExpenseColumn(
      id: json['id'] as String,
      title: json['title'] as String,
      requiresEntries: json['requiresEntries'] as bool? ?? true,
    );
  }
}

// Lancamento detalhado de despesa.
class ExpenseEntry {
  final String id;
  final String columnId;
  final DateTime date;
  final String category;
  final String reason;
  final double amount;
  final int? installmentCount;
  final int? installmentIndex;
  final DateTime? purchaseDate;

  ExpenseEntry({
    required this.id,
    required this.columnId,
    required this.date,
    required this.category,
    required this.reason,
    required this.amount,
    this.installmentCount,
    this.installmentIndex,
    this.purchaseDate,
  });

  // Copia o lancamento alterando somente os campos informados.
  ExpenseEntry copyWith({
    DateTime? date,
    String? category,
    String? reason,
    double? amount,
    int? installmentCount,
    int? installmentIndex,
    DateTime? purchaseDate,
  }) {
    return ExpenseEntry(
      id: id,
      columnId: columnId,
      date: date ?? this.date,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  // Indica se o lancamento representa parcela.
  bool get isInstallment =>
      installmentCount != null && installmentIndex != null && purchaseDate != null;

  // Serializa o lancamento.
  Map<String, dynamic> toJson() => {
        'id': id,
        'columnId': columnId,
        'date': date.millisecondsSinceEpoch,
        'category': category,
        'reason': reason,
        'amount': amount,
        'installmentCount': installmentCount,
        'installmentIndex': installmentIndex,
        'purchaseDate': purchaseDate?.millisecondsSinceEpoch,
      };

  // Reconstrui o lancamento a partir do JSON.
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      columnId: json['columnId'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      category: json['category'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      installmentCount: (json['installmentCount'] as num?)?.toInt(),
      installmentIndex: (json['installmentIndex'] as num?)?.toInt(),
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['purchaseDate'] as int),
    );
  }
}
