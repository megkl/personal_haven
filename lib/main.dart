import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/app_initializer.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/providers/theme_provider.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:personal_haven/services/social_auth_service.dart';
import 'firebase_options.dart';

const _appCheckProvider = String.fromEnvironment(
  'APP_CHECK_PROVIDER',
  defaultValue: 'auto',
);
const _appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

void main() {
  var crashlyticsReady = false;
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      try {
        await _activateAppCheck();
      } catch (error, stack) {
        debugPrint('Firebase App Check initialization failed: $error');
        debugPrintStack(stackTrace: stack);
      }

      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        try {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            !kDebugMode,
          );
          crashlyticsReady = true;
        } catch (error, stack) {
          debugPrint('Crashlytics initialization failed: $error');
          debugPrintStack(stackTrace: stack);
        }
      }

      runApp(const ProviderScope(child: PersonalHavenApp()));

      // Optional services must never delay or prevent the first app frame.
      unawaited(_initializeOptionalServices());
    },
    (error, stack) {
      debugPrint('Uncaught startup error: $error');
      debugPrintStack(stackTrace: stack);
      if (!kIsWeb && crashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

Future<void> _activateAppCheck() async {
  final useDebugAppCheck =
      _appCheckProvider == 'debug' ||
      (_appCheckProvider == 'auto' && !kReleaseMode);

  if (useDebugAppCheck) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(
        debugToken: _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken,
      ),
      providerApple: AppleDebugProvider(
        debugToken: _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken,
      ),
    );
    debugPrint('Firebase App Check debug provider active.');
  } else if (kReleaseMode && _appCheckProvider != 'none') {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleDeviceCheckProvider(),
    );
  } else {
    debugPrint('Skipping Firebase App Check.');
  }
}

Future<void> _initializeOptionalServices() async {
  try {
    await NotificationService.instance.initialize();
  } catch (error, stack) {
    debugPrint('Notification initialization failed: $error');
    debugPrintStack(stackTrace: stack);
  }

  try {
    await SocialAuthService.instance.initializeGoogle();
  } catch (error, stack) {
    debugPrint('Google Sign-In initialization failed: $error');
    debugPrintStack(stackTrace: stack);
  }
}

class PersonalHavenApp extends ConsumerWidget {
  const PersonalHavenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve persisted theme mode; fall back to system while loading.
    final themeMode = ref.watch(themeProvider).value ?? ThemeMode.system;

    return MaterialApp(
      title: 'Personal Haven',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      theme: AppTheme.light,
      //darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppInitializer(),
    );
  }
}
