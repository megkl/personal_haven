import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:personal_haven/services/notification_service.dart';

void main() {
  test('currency default follows supported device regions', () {
    expect(CurrencyFormatter.defaultCodeForCountry('KE'), 'KES');
    expect(CurrencyFormatter.defaultCodeForCountry('US'), 'USD');
    expect(CurrencyFormatter.defaultCodeForCountry('GB'), 'GBP');
    expect(CurrencyFormatter.defaultCodeForCountry('NG'), 'NGN');
    expect(CurrencyFormatter.defaultCodeForCountry('ZA'), 'ZAR');
    expect(CurrencyFormatter.defaultCodeForCountry('FR'), 'EUR');
    expect(CurrencyFormatter.defaultCodeForCountry('BG'), 'EUR');
    expect(CurrencyFormatter.defaultCodeForCountry('ME'), 'EUR');
    expect(CurrencyFormatter.defaultCodeForCountry(null), 'USD');
    expect(CurrencyFormatter.defaultCodeForCountry('JP'), 'USD');
  });

  test('fixed notification identifiers remain unique', () {
    const ids = <int>{
      NotificationIds.morningCheckin,
      NotificationIds.eveningMood,
      NotificationIds.journalPrompt,
      NotificationIds.mealReminder,
      NotificationIds.trialExpiring3Days,
      NotificationIds.trialExpiring1Day,
      NotificationIds.subscriptionExpired,
      NotificationIds.streakEncouragement,
      NotificationIds.weeklyMoodSummary,
      NotificationIds.noonStreakReminder,
      NotificationIds.testNotification,
    };

    expect(ids, hasLength(11));
  });
}
