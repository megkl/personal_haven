import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/splash_screen.dart';


class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hasSeenOnboardingAsync = ref.watch(hasSeenOnboardingProvider);

    return hasSeenOnboardingAsync.when(
      data: (hasSeenOnboarding) {
        if (authState.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }

        if (!hasSeenOnboarding) {
          return const SplashScreen();
        }

        if (!authState.isAuthenticated) {
          return const LoginScreen();
        }

        return const SplashScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (_, __) => const Scaffold(
        body: Center(
          child: Text('Error initializing app'),
        ),
      ),
    );
  }
}