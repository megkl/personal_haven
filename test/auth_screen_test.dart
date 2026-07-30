import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/presentation/screens/auth/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'isLoggedIn': false});
  });

  testWidgets('login screen remains usable on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Your Personal Haven.'), findsOneWidget);
    expect(find.text('Log in with Google'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Create one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up screen remains usable on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const SignUpScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Personal Haven.'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.textContaining('Privacy Policy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
