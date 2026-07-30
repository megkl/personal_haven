import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:personal_haven/presentation/widgets/common/network_avatar.dart';
import 'package:personal_haven/presentation/widgets/voice_dictation_button.dart';
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

  testWidgets('network avatar renders a local fallback without an image URL', (
    tester,
  ) async {
    const fallbackKey = Key('avatar-fallback');

    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkAvatar(
          size: 48,
          fallback: Icon(Icons.person, key: fallbackKey),
        ),
      ),
    );

    expect(find.byKey(fallbackKey), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('network avatar installs an image error fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkAvatar(
          size: 48,
          imageUrl: 'https://lh3.googleusercontent.com/avatar.png',
          fallback: Icon(Icons.person),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.errorBuilder, isNotNull);
  });

  testWidgets('voice dictation exposes an accessible microphone control', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Existing text');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            decoration: InputDecoration(
              suffixIcon: VoiceDictationButton(controller: controller),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byTooltip('Dictate with voice'), findsOneWidget);
    expect(controller.text, 'Existing text');
  });
}
