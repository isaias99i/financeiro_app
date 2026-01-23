// Mantem chaves legadas para compatibilidade com dados persistidos.
const String _legacySubcategoryListKey = 'columns';
const String _legacySubcategoryIdKey = 'columnId';

// Categoria de despesas com subcategorias.
class ExpenseCategory {
  ExpenseCategory({
    required this.id,
    required this.title,
    required this.subcategories,
  });

  final String id;
  String title;
  final List<ExpenseSubcategory> subcategories;

  // Serializa a categoria sem quebrar o formato persistido.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        _legacySubcategoryListKey:
            subcategories.map((subcategory) => subcategory.toJson()).toList(),
      };

  // Reconstrui a categoria a partir do JSON persistido.
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    final subcategoriesJson = json[_legacySubcategoryListKey] as List<dynamic>? ?? [];
    return ExpenseCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      subcategories: subcategoriesJson
          .map(
            (item) => ExpenseSubcategory.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// Subcategoria de despesas que pode exigir lancamentos detalhados.
class ExpenseSubcategory {
  ExpenseSubcategory({
    required this.id,
    required this.title,
    required this.requiresEntries,
  });

  final String id;
  String title;
  bool requiresEntries;

  // Serializa a subcategoria.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'requiresEntries': requiresEntries,
      };

  // Reconstrui a subcategoria a partir do JSON persistido.
  factory ExpenseSubcategory.fromJson(Map<String, dynamic> json) {
    return ExpenseSubcategory(
      id: json['id'] as String,
      title: json['title'] as String,
      requiresEntries: json['requiresEntries'] as bool? ?? true,
    );
  }
}

// Lancamento detalhado de despesa associado a uma subcategoria.
class ExpenseEntry {
  final String id;
  final String subcategoryId;
  final DateTime date;
  final String category;
  final String reason;
  final double amount;
  final int? installmentCount;
  final int? installmentIndex;
  final DateTime? purchaseDate;

  ExpenseEntry({
    required this.id,
    required this.subcategoryId,
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
      subcategoryId: subcategoryId,
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
      installmentCount != null &&
      installmentIndex != null &&
      purchaseDate != null;

  // Serializa o lancamento sem quebrar o formato persistido.
  Map<String, dynamic> toJson() => {
        'id': id,
        _legacySubcategoryIdKey: subcategoryId,
        'date': date.millisecondsSinceEpoch,
        'category': category,
        'reason': reason,
        'amount': amount,
        'installmentCount': installmentCount,
        'installmentIndex': installmentIndex,
        'purchaseDate': purchaseDate?.millisecondsSinceEpoch,
      };

  // Reconstrui o lancamento a partir do JSON persistido.
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      subcategoryId: json[_legacySubcategoryIdKey] as String,
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
