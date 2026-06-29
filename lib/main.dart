import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
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

void main() {
  var crashlyticsReady = false;
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
        crashlyticsReady = true;
      }

      await NotificationService.instance.initialize();
      await SocialAuthService.instance.initializeGoogle();
      runApp(const ProviderScope(child: PersonalHavenApp()));
    },
    (error, stack) {
      if (!kIsWeb && crashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
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
