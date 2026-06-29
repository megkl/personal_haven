import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/presentation/screens/home/home_screen.dart';
import 'package:personal_haven/presentation/screens/journal/journal_screen.dart';
import 'package:personal_haven/presentation/screens/profile/profile_screen.dart';
import 'package:personal_haven/presentation/screens/rituals/rituals_screen.dart';
import 'package:personal_haven/presentation/screens/subscription/subscription_screen.dart';
import 'package:personal_haven/presentation/screens/wellness/wellness_screen.dart';
import 'package:personal_haven/providers/subscription_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key, this.currentIndex = 0});

  final int currentIndex;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final hasAccess =
        subscriptionState.isLoading || subscriptionState.hasFullAccess;
    final screens = [
      const HomeScreen(),
      hasAccess ? const JournalScreen() : const _SubscriptionLockedScreen(),
      hasAccess ? const WellnessScreen() : const _SubscriptionLockedScreen(),
      const RitualsScreen(),
      ProfileScreen(),
    ];

    final effectiveIndex =
        !hasAccess && (_selectedIndex == 1 || _selectedIndex == 2)
        ? 0
        : _selectedIndex;
    if (effectiveIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = effectiveIndex);
        }
      });
    }

    return Scaffold(
      backgroundColor: effectiveIndex == 0 ? const Color(0xFFB8E6E3) : null,
      body: IndexedStack(index: effectiveIndex, children: screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: context.colors.navBar,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.35 : 0.15,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.menu_book_outlined, 'Journal', 1),
              _buildNavItem(Icons.spa, 'Wellness', 2),
              _buildNavItem(Icons.rice_bowl, 'Rituals', 3),
              _buildNavItem(
                hasAccess ? Icons.person : Icons.settings,
                hasAccess ? 'Profile' : 'Settings',
                4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final subscriptionState = ref.watch(subscriptionProvider);
    final hasAccess =
        subscriptionState.isLoading || subscriptionState.hasFullAccess;
    final isLocked = !hasAccess && (index == 1 || index == 2);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (isLocked) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocked ? Icons.lock_outline : icon,
                  color: isSelected
                      ? Colors.white
                      : context.colors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionLockedScreen extends StatelessWidget {
  const _SubscriptionLockedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Your free trial has ended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to unlock this section again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  ),
                  child: const Text('View Plans'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
