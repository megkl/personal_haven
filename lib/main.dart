import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/app_initializer.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/providers/theme_provider.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:personal_haven/services/social_auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.initialize();
  await SocialAuthService.instance.initializeGoogle();
  runApp(const ProviderScope(child: PersonalHavenApp()));
}

class PersonalHavenApp extends ConsumerWidget {
  const PersonalHavenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve persisted theme mode; fall back to system while loading.
    final themeMode =
        ref.watch(themeProvider).value ?? ThemeMode.system;

    return MaterialApp(
      title: 'Personal Haven',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      //darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppInitializer(),
    );
  }
}
