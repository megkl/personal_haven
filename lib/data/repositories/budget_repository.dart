import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:personal_haven/data/data_sources/local/cache_helper.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final _fs = FirestoreService.instance;
  final _cache = CacheHelper();
  final _uuid = const Uuid();
  static const _col = 'transactions';
  static const _cacheDuration = Duration(hours: 1);

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<BudgetTransaction> createTransaction({
    required String userId,
    required String type,
    required double amount,
    required String category,
    String? description,
    DateTime? transactionDate,
  }) async {
    final tx = BudgetTransaction(
      id: _uuid.v4(),
      userId: userId,
      type: type.toLowerCase(),
      amount: amount,
      category: category,
      description: description,
      transactionDate: transactionDate ?? DateTime.now(),
    );
    await _fs.set(userId, _col, tx.id, tx.toFirestore());
    // Invalidate cache
    await _cache.clearData(userId, _col);
    return tx;
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all transactions for the user, using the local cache when valid.
  Future<List<BudgetTransaction>> getAllTransactions(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getData(
        userId,
        _col,
        fromJson: (json) =>
            BudgetTransaction.fromJson(json as Map<String, dynamic>),
        expiry: _cacheDuration,
      );
      if (cached != null) return cached;
    }

    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('transactionDate', descending: true));
    final transactions =
        snap.docs.map((d) => BudgetTransaction.fromFirestore(d)).toList();

    await _cache.saveData(userId, _col, transactions,
        toJson: (t) => t.toJson());

    return transactions;
  }

  Future<List<BudgetTransaction>> getThisMonthTransactions(
    String userId, {
    bool forceRefresh = false,
  }) async {
    final all = await getAllTransactions(userId, forceRefresh: forceRefresh);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return all
        .where((t) =>
            t.transactionDate.isAfter(monthStart) &&
            t.transactionDate.isBefore(monthEnd))
        .toList();
  }

  Future<List<BudgetTransaction>> getRecentTransactions(String userId,
      {int limit = 10}) async {
    final all = await getAllTransactions(userId);
    return all.take(limit).toList();
  }

  Future<Map<String, double>> getMonthlyTotals(String userId) async {
    final txs = await getThisMonthTransactions(userId);
    double income = 0, expenses = 0;
    for (final t in txs) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expenses += t.amount;
      }
    }
    return {
      'income': income,
      'expenses': expenses,
      'balance': income - expenses,
    };
  }

  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final txs = await getThisMonthTransactions(userId);
    final map = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Future<Map<String, double>> getIncomeByCategory(String userId) async {
    final txs = await getThisMonthTransactions(userId);
    final map = <String, double>{};
    for (final t in txs.where((t) => t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Future<double> getTotalIncome(String userId) async {
    final totals = await getMonthlyTotals(userId);
    return totals['income'] ?? 0;
  }

  Future<double> getTotalExpenses(String userId) async {
    final totals = await getMonthlyTotals(userId);
    return totals['expenses'] ?? 0;
  }

  Future<double> getBalance(String userId) async {
    final totals = await getMonthlyTotals(userId);
    return totals['balance'] ?? 0;
  }

  Future<Map<int, double>> getDailySpending(String userId) async {
    final txs = await getThisMonthTransactions(userId);
    final map = <int, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      final day = t.transactionDate.day;
      map[day] = (map[day] ?? 0) + t.amount;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getWeeklyTotals(String userId) async {
    final txs = await getThisMonthTransactions(userId);
    final weeks = <int, Map<String, double>>{};
    for (final t in txs) {
      final week = (t.transactionDate.day / 7).ceil();
      weeks.putIfAbsent(week, () => {'income': 0, 'expenses': 0});
      if (t.isIncome) {
        weeks[week]!['income'] = (weeks[week]!['income'] ?? 0) + t.amount;
      } else {
        weeks[week]!['expenses'] =
            (weeks[week]!['expenses'] ?? 0) + t.amount;
      }
    }
    return weeks.entries
        .map((e) => {'week': e.key, ...e.value})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSpendingSummary(String userId) async {
    final categoryTotals = await getExpensesByCategory(userId);
    final total = categoryTotals.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return [];
    final summary = categoryTotals.entries.map((e) => {
          'category': e.key,
          'amount': e.value,
          'percentage': (e.value / total) * 100,
          'icon': TransactionCategories.getIcon(e.key, false),
        }).toList();
    summary.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return summary;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> updateTransaction(BudgetTransaction tx) async {
    await _fs.set(tx.userId, _col, tx.id, tx.toFirestore());
    // Invalidate cache
    await _cache.clearData(tx.userId, _col);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteTransaction(String userId, String txId) async {
    await _fs.delete(userId, _col, txId);
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }

  Future<void> deleteAllTransactions(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }
}
