import 'package:personal_haven/data/data_sources/local/dao/transaction_dao.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final BudgetTransactionDao _transactionDao;
  final Uuid _uuid = const Uuid();

  TransactionRepository({BudgetTransactionDao? transactionDao})
      : _transactionDao = transactionDao ?? BudgetTransactionDao();

  Future<BudgetTransaction> createTransaction({
    required String userId,
    required String type,
    required double amount,
    required String category,
    String? description,
  }) async {
    final transaction = BudgetTransaction(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      amount: amount,
      category: category,
      description: description,
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _transactionDao.insert(transaction);
    return transaction;
  }

  Future<List<BudgetTransaction>> getAllTransactions(String userId) async {
    return await _transactionDao.getAllByUserId(userId);
  }

  Future<List<BudgetTransaction>> getThisMonthTransactions(String userId) async {
    return await _transactionDao.getThisMonthBudgetTransactions(userId);
  }

  Future<Map<String, double>> getMonthlyTotals(String userId) async {
    return await _transactionDao.getMonthlyTotals(userId);
  }

  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    return await _transactionDao.getExpensesByCategory(userId);
  }

  Future<void> updateTransaction(BudgetTransaction transaction) async {
    await _transactionDao.update(transaction);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactionDao.delete(transactionId);
  }
}
