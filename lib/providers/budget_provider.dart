import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:personal_haven/data/repositories/budget_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionState {
  final List<BudgetTransaction> transactions;
  final bool isLoading;
  final String? error;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<BudgetTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalIncome {
    return transactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return transactions
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpenses;
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repository;
  final String _userId;

  TransactionNotifier(this._repository, this._userId) : super(TransactionState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _repository.getThisMonthTransactions(_userId);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: ${e.toString()}',
      );
    }
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? description,
  }) async {
    try {
      final newTransaction = await _repository.createTransaction(
        userId: _userId,
        type: type,
        amount: amount,
        category: category,
        description: description,
      );
      state = state.copyWith(
        transactions: [newTransaction, ...state.transactions],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to add transaction: ${e.toString()}');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _repository.deleteTransaction(transactionId);
      final updated = state.transactions.where((t) => t.id != transactionId).toList();
      state = state.copyWith(transactions: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete transaction: ${e.toString()}');
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return TransactionNotifier(repository, userId);
});
