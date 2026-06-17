import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BudgetReviewCadence {
  monthly('monthly', 'Monthly'),
  quarterly('quarterly', 'Quarterly'),
  yearly('yearly', 'Yearly');

  const BudgetReviewCadence(this.value, this.label);

  final String value;
  final String label;

  static BudgetReviewCadence fromValue(String? value) {
    return BudgetReviewCadence.values.firstWhere(
      (cadence) => cadence.value == value,
      orElse: () => BudgetReviewCadence.monthly,
    );
  }
}

class InsightsSettings {
  final BudgetReviewCadence budgetReviewCadence;

  const InsightsSettings({
    this.budgetReviewCadence = BudgetReviewCadence.monthly,
  });

  InsightsSettings copyWith({BudgetReviewCadence? budgetReviewCadence}) {
    return InsightsSettings(
      budgetReviewCadence: budgetReviewCadence ?? this.budgetReviewCadence,
    );
  }
}

final insightsSettingsProvider =
    NotifierProvider<InsightsSettingsNotifier, InsightsSettings>(
      InsightsSettingsNotifier.new,
    );

class InsightsSettingsNotifier extends Notifier<InsightsSettings> {
  static const _budgetReviewCadenceKey = 'insights_budget_review_cadence';

  @override
  InsightsSettings build() {
    Future.microtask(load);
    return const InsightsSettings();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      budgetReviewCadence: BudgetReviewCadence.fromValue(
        prefs.getString(_budgetReviewCadenceKey),
      ),
    );
  }

  Future<void> setBudgetReviewCadence(BudgetReviewCadence cadence) async {
    state = state.copyWith(budgetReviewCadence: cadence);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetReviewCadenceKey, cadence.value);
  }
}
