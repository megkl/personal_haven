import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:personal_haven/providers/budget_provider.dart';
import 'package:personal_haven/providers/currency_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final income = transactionState.totalIncome;
    final expenses = transactionState.totalExpenses;
    final balance = transactionState.balance;
    final currencyCode =
        ref.watch(currencyProvider).value ?? CurrencyFormatter.defaultCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: transactionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOverviewCard(
                  context,
                  ref,
                  income,
                  expenses,
                  balance,
                  currencyCode,
                ),

                // Category breakdown (if has expenses)
                if (transactionState.expensesByCategory.isNotEmpty)
                  _buildCategoryBreakdown(
                    context,
                    transactionState.expensesByCategory,
                    expenses,
                  ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(transactionProvider.notifier)
                          .loadTransactions();
                    },
                    child: transactionState.transactions.isEmpty
                        ? _buildEmptyState(context, ref)
                        : _buildTransactionsList(
                            context,
                            ref,
                            transactionState.transactions,
                            currencyCode,
                          ),
                  ),
                ),
              ],
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showAddTransactionSheet(context, ref),
      //   backgroundColor: AppColors.primary,
      //   child: Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    WidgetRef ref,
    double income,
    double expenses,
    double balance,
    String currencyCode,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (balance >= 0 ? AppColors.primary : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  balance >= 0 ? 'On track' : 'Over',
                  style: TextStyle(
                    fontSize: 9,
                    color: balance >= 0 ? AppColors.primaryDark : Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance.abs(), currencyCode),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildOverviewRow(
            context: context,
            icon: Icons.arrow_downward_rounded,
            label: 'Income',
            amount: income,
            currencyCode: currencyCode,
            color: Colors.green,
            actionLabel: 'Add',
            actionIcon: Icons.add_rounded,
            onTap: () => _showAddTransactionDialog(context, ref, 'income'),
          ),
          const SizedBox(height: 8),
          _buildOverviewRow(
            context: context,
            icon: Icons.arrow_upward_rounded,
            label: 'Expenses',
            amount: expenses,
            currencyCode: currencyCode,
            color: Colors.red,
            actionLabel: 'Add',
            actionIcon: Icons.add_rounded,
            onTap: () => _showAddTransactionDialog(context, ref, 'expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double amount,
    required String currencyCode,
    required Color color,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(amount, currencyCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildActionButton(label: actionLabel, icon: actionIcon, onTap: onTap),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    Map<String, double> expensesByCategory,
    double totalExpenses,
  ) {
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final entry = sortedCategories[index];
          final percentage = totalExpenses > 0
              ? (entry.value / totalExpenses * 100)
              : 0.0;
          final icon = TransactionCategories.getIcon(entry.key, false);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.colors.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Text(
                  entry.key,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    WidgetRef ref,
    List<BudgetTransaction> transactions,
    String currencyCode,
  ) {
    // Group transactions by date
    final grouped = <String, List<BudgetTransaction>>{};
    for (var t in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayTransactions = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            ...dayTransactions.map(
              (t) => _buildTransactionItem(context, ref, t, currencyCode),
            ),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) return 'Today';
    if (transactionDate == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }

  Widget _buildTransactionItem(
    BuildContext context,
    WidgetRef ref,
    BudgetTransaction transaction,
    String currencyCode,
  ) {
    final isIncome = transaction.isIncome;
    final icon = TransactionCategories.getIcon(transaction.category, isIncome);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Transaction'),
            content: Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(transactionProvider.notifier)
            .deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (isIncome ? Colors.green : Colors.red).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: 19))),
            ),
            const SizedBox(width: 10),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3E40),
                    ),
                  ),
                  if (transaction.description != null &&
                      transaction.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        transaction.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      DateFormat('h:mm a').format(transaction.transactionDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, currencyCode)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.cardColor2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your income and expenses',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final isIncome = type == 'income';
    final currencyCode =
        ref.read(currencyProvider).value ?? CurrencyFormatter.defaultCode;
    final currencySymbol = CurrencyFormatter.optionFor(currencyCode).symbol;

    final categories = isIncome
        ? TransactionCategories.getIncomeNames()
        : TransactionCategories.getExpenseNames();

    String selectedCategory = categories.first;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isIncome ? '➕ New Income' : '➖ New Expense',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      hintText: 'Amount *',
                      prefixText: currencySymbol,
                      hintStyle: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: context.colors.cardColor2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      hintText: 'Category',
                      filled: true,
                      fillColor: context.colors.cardColor2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    items: categories.map((cat) {
                      final icon = TransactionCategories.getIcon(cat, isIncome);
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(icon),
                            const SizedBox(width: 10),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Add details (optional)',
                      hintStyle: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: context.colors.cardColor2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.cardColor2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'EEE, MMM d, yyyy',
                              ).format(selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amountText = amountController.text.trim();
                        if (amountText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an amount'),
                            ),
                          );
                          return;
                        }

                        final amount = double.tryParse(amountText);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                            ),
                          );
                          return;
                        }

                        ref
                            .read(transactionProvider.notifier)
                            .addTransaction(
                              type: type,
                              amount: amount,
                              category: selectedCategory,
                              description: descriptionController.text.isNotEmpty
                                  ? descriptionController.text.trim()
                                  : null,
                              date: selectedDate,
                            );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isIncome ? 'Income' : 'Expense'} added!',
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isIncome ? 'Add Income' : 'Add Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
