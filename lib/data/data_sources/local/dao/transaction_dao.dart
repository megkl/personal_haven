import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:sqflite/sqflite.dart';

class BudgetTransactionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  Future<void> insert(BudgetTransaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAll(List<BudgetTransaction> transactions) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var transaction in transactions) {
      batch.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  Future<BudgetTransaction?> getById(String transactionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BudgetTransaction.fromMap(maps.first);
  }

  Future<List<BudgetTransaction>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getByType(String userId, String type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND transaction_type = ?',
      whereArgs: [userId, type],
      orderBy: 'transaction_date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getByCategory(String userId, String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND category_id = ?',
      whereArgs: [userId, category],
      orderBy: 'transaction_date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getThisMonthTransactions(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [
        userId,
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
      orderBy: 'transaction_date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'transaction_date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC',
      limit: limit,
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, double>> getMonthlyTotals(String userId) async {
    final transactions = await getThisMonthTransactions(userId);
    double income = 0;
    double expenses = 0;

    for (var transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
      }
    }

    return {
      'income': income,
      'expenses': expenses,
      'balance': income - expenses,
    };
  }

  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final expenses = await getByType(userId, 'expense');
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  Future<Map<String, double>> getThisMonthExpensesByCategory(String userId) async {
    final transactions = await getThisMonthTransactions(userId);
    final expenses = transactions.where((t) => t.isExpense);
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  Future<Map<String, double>> getIncomeByCategory(String userId) async {
    final incomes = await getByType(userId, 'income');
    final Map<String, double> categoryTotals = {};

    for (var income in incomes) {
      categoryTotals[income.category] =
          (categoryTotals[income.category] ?? 0) + income.amount;
    }

    return categoryTotals;
  }

 Future<double> getTotalIncome(String userId) async {
  final transactions = await getThisMonthTransactions(userId);
  double total = 0.0;

  for (final t in transactions) {
    if (t.isIncome) {
      total += t.amount;
    }
  }

  return total;
}

  Future<double> getTotalExpenses(String userId) async {
  final transactions = await getThisMonthTransactions(userId);
  double total = 0.0;

  for (final t in transactions) {
    if (t.isExpense) {
      total += t.amount;
    }
  }

  return total;
}

  /// Get daily spending for the current month (for charts)
  Future<Map<int, double>> getDailySpending(String userId) async {
    final transactions = await getThisMonthTransactions(userId);
    final expenses = transactions.where((t) => t.isExpense);
    final Map<int, double> dailyTotals = {};

    for (var expense in expenses) {
      final day = expense.transactionDate.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    return dailyTotals;
  }

  /// Get weekly totals for the current month
  Future<List<Map<String, dynamic>>> getWeeklyTotals(String userId) async {
    final transactions = await getThisMonthTransactions(userId);
    final now = DateTime.now();
    final weeksInMonth = ((now.day + DateTime(now.year, now.month, 1).weekday - 1) / 7).ceil();
    
    List<Map<String, dynamic>> weeklyData = [];
    
    for (int week = 1; week <= weeksInMonth; week++) {
      double income = 0;
      double expenses = 0;
      
      for (var t in transactions) {
        final transactionWeek = ((t.transactionDate.day + 
            DateTime(t.transactionDate.year, t.transactionDate.month, 1).weekday - 1) / 7).ceil();
        
        if (transactionWeek == week) {
          if (t.isIncome) {
            income += t.amount;
          } else {
            expenses += t.amount;
          }
        }
      }
      
      weeklyData.add({
        'week': week,
        'income': income,
        'expenses': expenses,
      });
    }
    
    return weeklyData;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  Future<int> update(BudgetTransaction transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'transaction_id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  Future<int> delete(String transactionId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<int> deleteAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'user_id = ? AND transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );
  }
}