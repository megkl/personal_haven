import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('onboarding remains usable on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('A quiet place for your thoughts'), findsOneWidget);
    expect(find.byTooltip('Next'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bring your day into focus'), findsOneWidget);
    expect(find.byTooltip('Previous'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('A quiet place for your thoughts'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Small steps, meaningful progress'), findsOneWidget);
    expect(find.byTooltip('Get started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding advances after the progress timer completes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bring your day into focus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
