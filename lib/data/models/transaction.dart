import 'package:equatable/equatable.dart';

class BudgetTransaction extends Equatable {
  final String id;
  final String userId;
  final String? budgetId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? description;
  final DateTime transactionDate;

  const BudgetTransaction({
    required this.id,
    required this.userId,
    this.budgetId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.transactionDate,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  BudgetTransaction copyWith({
    String? id,
    String? userId,
    String? budgetId,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? transactionDate,
  }) {
    return BudgetTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      budgetId: budgetId ?? this.budgetId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'transaction_id': id,
      'user_id': userId,
      'budget_id': budgetId,
      'transaction_type': type,
      'amount': amount,
      'category_id': category, // Maps to category_id in DB
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }

  /// Create from database Map
  factory BudgetTransaction.fromMap(Map<String, dynamic> map) {
    return BudgetTransaction(
      id: map['transaction_id'] as String,
      userId: map['user_id'] as String,
      budgetId: map['budget_id'] as String?,
      type: map['transaction_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: (map['category_id'] ?? 'Other') as String, // Read from category_id
      description: map['description'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        budgetId,
        type,
        amount,
        category,
        description,
        transactionDate,
      ];

  @override
  String toString() {
    return 'BudgetTransaction(id: $id, type: $type, amount: $amount, category: $category)';
  }
}

/// Budget model for monthly budgets
class Budget extends Equatable {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double totalIncome;
  final double? budgetLimit;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.totalIncome,
    this.budgetLimit,
    required this.createdAt,
  });

  Budget copyWith({
    String? id,
    String? userId,
    int? month,
    int? year,
    double? totalIncome,
    double? budgetLimit,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      totalIncome: totalIncome ?? this.totalIncome,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budget_id': id,
      'user_id': userId,
      'month': month,
      'year': year,
      'total_income': totalIncome,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['budget_id'] as String,
      userId: map['user_id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      totalIncome: (map['total_income'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, month, year, totalIncome, budgetLimit, createdAt];
}

/// Transaction categories with icons and colors
class TransactionCategory {
  final String name;
  final String icon;
  final bool isIncome;

  const TransactionCategory({
    required this.name,
    required this.icon,
    required this.isIncome,
  });
}

class TransactionCategories {
  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(name: 'Salary', icon: '💰', isIncome: true),
    TransactionCategory(name: 'Business', icon: '💼', isIncome: true),
    TransactionCategory(name: 'Investment', icon: '📈', isIncome: true),
    TransactionCategory(name: 'Freelance', icon: '💻', isIncome: true),
    TransactionCategory(name: 'Gift', icon: '🎁', isIncome: true),
    TransactionCategory(name: 'Refund', icon: '↩️', isIncome: true),
    TransactionCategory(name: 'Other', icon: '📥', isIncome: true),
  ];

  static const List<TransactionCategory> expenseCategories = [
    TransactionCategory(name: 'Food', icon: '🍔', isIncome: false),
    TransactionCategory(name: 'Transport', icon: '🚗', isIncome: false),
    TransactionCategory(name: 'Shopping', icon: '🛍️', isIncome: false),
    TransactionCategory(name: 'Bills', icon: '📄', isIncome: false),
    TransactionCategory(name: 'Entertainment', icon: '🎬', isIncome: false),
    TransactionCategory(name: 'Health', icon: '🏥', isIncome: false),
    TransactionCategory(name: 'Education', icon: '📚', isIncome: false),
    TransactionCategory(name: 'Groceries', icon: '🛒', isIncome: false),
    TransactionCategory(name: 'Utilities', icon: '💡', isIncome: false),
    TransactionCategory(name: 'Rent', icon: '🏠', isIncome: false),
    TransactionCategory(name: 'Insurance', icon: '🛡️', isIncome: false),
    TransactionCategory(name: 'Personal Care', icon: '💅', isIncome: false),
    TransactionCategory(name: 'Other', icon: '📤', isIncome: false),
  ];

  static String getIcon(String categoryName, bool isIncome) {
    final categories = isIncome ? incomeCategories : expenseCategories;
    try {
      return categories.firstWhere((c) => c.name == categoryName).icon;
    } catch (_) {
      return isIncome ? '📥' : '📤';
    }
  }

  static List<String> getIncomeNames() => incomeCategories.map((c) => c.name).toList();
  static List<String> getExpenseNames() => expenseCategories.map((c) => c.name).toList();
}