import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/services/notification_service.dart';

void main() {
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
      NotificationIds.testNotification,
    };

    expect(ids, hasLength(10));
  });
}
