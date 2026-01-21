import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final income = transactionState.totalIncome;
    final expenses = transactionState.totalExpenses;
    final balance = transactionState.balance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: transactionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOverviewCard(income, expenses, balance),
                _buildQuickActions(context, ref),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(transactionProvider.notifier).loadTransactions();
                    },
                    child: transactionState.transactions.isEmpty
                        ? _buildEmptyState(context, ref)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: transactionState.transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactionState.transactions[index];
                              return _buildTransactionItem(context, ref, transaction);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewCard(double income, double expenses, double balance) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: balance >= 0
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (balance >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'This Month',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance >= 0 ? 'Remaining' : 'Over budget',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Income',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${income.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Expenses',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${expenses.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddTransactionDialog(context, ref, 'income'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Income'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddTransactionDialog(context, ref, 'expense'),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, WidgetRef ref, transaction) {
    final isIncome = transaction.isIncome;
    
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(transactionProvider.notifier).deleteTransaction(transaction.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isIncome ? Colors.green : Colors.red,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (transaction.description != null)
                    Text(
                      transaction.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(transaction.transactionDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add income or expense to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref, String type) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = type == 'income' ? 'Salary' : 'Food';

    final categories = type == 'income'
        ? ['Salary', 'Business', 'Investment', 'Gift', 'Other']
        : ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type == 'income' ? 'Income' : 'Expense'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g., 100.00',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add details',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                ref.read(transactionProvider.notifier).addTransaction(
                      type: type,
                      amount: double.parse(amountController.text),
                      category: selectedCategory,
                      description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}