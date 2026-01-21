import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/transaction.dart';

class BudgetTransactionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(BudgetTransaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert('transactions', transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<BudgetTransaction>> getThisMonthBudgetTransactions(String userId) async {
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

  Future<Map<String, double>> getMonthlyTotals(String userId) async {
    final transactions = await getThisMonthBudgetTransactions(userId);
    
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

  Future<int> update(BudgetTransaction transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'transaction_id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> delete(String transactionId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }
}
