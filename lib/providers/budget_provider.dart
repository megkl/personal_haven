import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:personal_haven/data/repositories/budget_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'budget_provider.g.dart';
// ─────────────────────────────────────────────────────────────
// Repository Provider
// ─────────────────────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// ─────────────────────────────────────────────────────────────
// Transaction State
// ─────────────────────────────────────────────────────────────

class TransactionState {
  final List<BudgetTransaction> transactions;
  final Map<String, double> expensesByCategory;
  final bool isLoading;
  final String? error;

  TransactionState({
    this.transactions = const [],
    this.expensesByCategory = const {},
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<BudgetTransaction>? transactions,
    Map<String, double>? expensesByCategory,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Computed properties
  double get totalIncome {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpenses;

  List<BudgetTransaction> get incomeTransactions =>
      transactions.where((t) => t.isIncome).toList();

  List<BudgetTransaction> get expenseTransactions =>
      transactions.where((t) => t.isExpense).toList();

  List<BudgetTransaction> get recentTransactions =>
      transactions.take(5).toList();

  /// Get top spending categories
  List<MapEntry<String, double>> get topExpenseCategories {
    final sorted = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// Transaction Notifier
// ─────────────────────────────────────────────────────────────

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  final TransactionRepository _repository = TransactionRepository();

  String get _userId => ref.read(currentUserIdProvider);

  @override
  TransactionState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isNotEmpty) {
      Future.microtask(loadTransactions);
    }
    return TransactionState();
  }

  /// Load all transactions for current month
  Future<void> loadTransactions() async {
    if (!ref.mounted) return;
    final userId = _userId;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _repository.getThisMonthTransactions(userId);
      if (!ref.mounted) return;

      final expensesByCategory = await _repository.getExpensesByCategory(
        userId,
      );
      if (!ref.mounted) return;

      state = state.copyWith(
        transactions: transactions,
        expensesByCategory: expensesByCategory,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: ${e.toString()}',
      );
    }
  }

  /// Add a new transaction
  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    if (!ref.mounted) return;
    final userId = _userId;

    try {
      final newTransaction = await _repository.createTransaction(
        userId: userId,
        type: type,
        amount: amount,
        category: category,
        description: description,
        transactionDate: date,
      );
      if (!ref.mounted) return;

      // Update state with new transaction
      final updatedTransactions = [newTransaction, ...state.transactions];

      // Update category totals if expense
      Map<String, double> updatedCategories = Map.from(
        state.expensesByCategory,
      );
      if (type.toLowerCase() == 'expense') {
        updatedCategories[category] =
            (updatedCategories[category] ?? 0) + amount;
      }

      state = state.copyWith(
        transactions: updatedTransactions,
        expensesByCategory: updatedCategories,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        error: 'Failed to add transaction: ${e.toString()}',
      );
    }
  }

  /// Add income shortcut
  Future<void> addIncome({
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    await addTransaction(
      type: 'income',
      amount: amount,
      category: category,
      description: description,
      date: date,
    );
  }

  /// Add expense shortcut
  Future<void> addExpense({
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    await addTransaction(
      type: 'expense',
      amount: amount,
      category: category,
      description: description,
      date: date,
    );
  }

  /// Update an existing transaction
  Future<void> updateTransaction(BudgetTransaction transaction) async {
    if (!ref.mounted) return;
    final userId = _userId;

    try {
      await _repository.updateTransaction(transaction);
      if (!ref.mounted) return;

      final updatedTransactions = state.transactions.map((t) {
        return t.id == transaction.id ? transaction : t;
      }).toList();

      // Recalculate category totals
      final expensesByCategory = await _repository.getExpensesByCategory(
        userId,
      );
      if (!ref.mounted) return;

      state = state.copyWith(
        transactions: updatedTransactions,
        expensesByCategory: expensesByCategory,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        error: 'Failed to update transaction: ${e.toString()}',
      );
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    if (!ref.mounted) return;
    final userId = _userId;

    try {
      final currentState = state;
      final transaction = currentState.transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      await _repository.deleteTransaction(userId, transactionId);
      if (!ref.mounted) return;

      final updatedTransactions = currentState.transactions
          .where((t) => t.id != transactionId)
          .toList();
      Map<String, double> updatedCategories = Map.from(
        currentState.expensesByCategory,
      );
      if (transaction.isExpense) {
        final newAmount =
            (updatedCategories[transaction.category] ?? 0) - transaction.amount;
        if (newAmount <= 0) {
          updatedCategories.remove(transaction.category);
        } else {
          updatedCategories[transaction.category] = newAmount;
        }
      }
      state = state.copyWith(
        transactions: updatedTransactions,
        expensesByCategory: updatedCategories,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        error: 'Failed to delete transaction: ${e.toString()}',
      );
    }
  }

  /// Clear all transactions
  Future<void> clearAllTransactions() async {
    if (!ref.mounted) return;
    final userId = _userId;

    try {
      await _repository.deleteAllTransactions(userId);
      if (!ref.mounted) return;

      state = state.copyWith(transactions: [], expensesByCategory: {});
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        error: 'Failed to clear transactions: ${e.toString()}',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider for monthly totals
final monthlyTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getMonthlyTotals(userId);
});

/// Provider for spending summary by category
final spendingSummaryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getSpendingSummary(userId);
});

/// Provider for weekly totals (for charts)
final weeklyTotalsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getWeeklyTotals(userId);
});

/// Provider for daily spending (for charts)
final dailySpendingProvider = FutureProvider<Map<int, double>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getDailySpending(userId);
});
