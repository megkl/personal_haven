
import 'package:personal_haven/data/data_sources/local/dao/transaction_dao.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final BudgetTransactionDao _transactionDao;
  final Uuid _uuid = const Uuid();

  TransactionRepository({BudgetTransactionDao? transactionDao})
      : _transactionDao = transactionDao ?? BudgetTransactionDao();

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  Future<BudgetTransaction> createTransaction({
    required String userId,
    required String type,
    required double amount,
    required String category,
    String? description,
    DateTime? transactionDate,
  }) async {
    final transaction = BudgetTransaction(
      id: _uuid.v4(),
      userId: userId,
      type: type.toLowerCase(),
      amount: amount,
      category: category,
      description: description,
      transactionDate: transactionDate ?? DateTime.now(),
    );

    await _transactionDao.insert(transaction);
    return transaction;
  }

  Future<void> addIncome({
    required String userId,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    await createTransaction(
      userId: userId,
      type: 'income',
      amount: amount,
      category: category,
      description: description,
      transactionDate: date,
    );
  }

  Future<void> addExpense({
    required String userId,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    await createTransaction(
      userId: userId,
      type: 'expense',
      amount: amount,
      category: category,
      description: description,
      transactionDate: date,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  Future<BudgetTransaction?> getTransactionById(String transactionId) async {
    return await _transactionDao.getById(transactionId);
  }

  Future<List<BudgetTransaction>> getAllTransactions(String userId) async {
    return await _transactionDao.getAllByUserId(userId);
  }

  Future<List<BudgetTransaction>> getThisMonthTransactions(String userId) async {
    return await _transactionDao.getThisMonthTransactions(userId);
  }

  Future<List<BudgetTransaction>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _transactionDao.getByDateRange(userId, startDate, endDate);
  }

  Future<List<BudgetTransaction>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) async {
    return await _transactionDao.getRecentTransactions(userId, limit: limit);
  }

  Future<List<BudgetTransaction>> getIncomeTransactions(String userId) async {
    return await _transactionDao.getByType(userId, 'income');
  }

  Future<List<BudgetTransaction>> getExpenseTransactions(String userId) async {
    return await _transactionDao.getByType(userId, 'expense');
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, double>> getMonthlyTotals(String userId) async {
    return await _transactionDao.getMonthlyTotals(userId);
  }

  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    return await _transactionDao.getThisMonthExpensesByCategory(userId);
  }

  Future<Map<String, double>> getIncomeByCategory(String userId) async {
    return await _transactionDao.getIncomeByCategory(userId);
  }

  Future<double> getTotalIncome(String userId) async {
    return await _transactionDao.getTotalIncome(userId);
  }

  Future<double> getTotalExpenses(String userId) async {
    return await _transactionDao.getTotalExpenses(userId);
  }

  Future<double> getBalance(String userId) async {
    final totals = await getMonthlyTotals(userId);
    return totals['balance'] ?? 0.0;
  }

  Future<Map<int, double>> getDailySpending(String userId) async {
    return await _transactionDao.getDailySpending(userId);
  }

  Future<List<Map<String, dynamic>>> getWeeklyTotals(String userId) async {
    return await _transactionDao.getWeeklyTotals(userId);
  }

  /// Get spending summary with percentage by category
  Future<List<Map<String, dynamic>>> getSpendingSummary(String userId) async {
    final categoryTotals = await getExpensesByCategory(userId);
    final totalExpenses = categoryTotals.values.fold(0.0, (sum, val) => sum + val);

    if (totalExpenses == 0) return [];

    final summary = categoryTotals.entries.map((entry) {
      final percentage = (entry.value / totalExpenses) * 100;
      return {
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage,
        'icon': TransactionCategories.getIcon(entry.key, false),
      };
    }).toList();

    // Sort by amount descending
    summary.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return summary;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  Future<void> updateTransaction(BudgetTransaction transaction) async {
    await _transactionDao.update(transaction);
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  Future<void> deleteTransaction(String transactionId) async {
    await _transactionDao.delete(transactionId);
  }

  Future<void> deleteAllTransactions(String userId) async {
    await _transactionDao.deleteAllByUserId(userId);
  }
}