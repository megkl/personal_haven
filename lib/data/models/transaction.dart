
import 'package:equatable/equatable.dart';

class BudgetTransaction extends Equatable {
  final String id;
  final String userId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;

  const BudgetTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.transactionDate,
    required this.createdAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  BudgetTransaction copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return BudgetTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': id,
      'user_id': userId,
      'transaction_type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetTransaction.fromMap(Map<String, dynamic> map) {
    return BudgetTransaction(
      id: map['transaction_id'] as String,
      userId: map['user_id'] as String,
      type: map['transaction_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amount,
        category,
        description,
        transactionDate,
        createdAt,
      ];
}
