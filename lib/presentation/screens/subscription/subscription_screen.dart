import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/subscription.dart';
import 'package:personal_haven/providers/subscription_provider.dart';
import 'package:personal_haven/services/iap_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;
  bool _isProcessing = false;
  bool _isRestoring = false;

  Future<void> _subscribe() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _handleStorePurchase();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleStorePurchase() async {
    final result = await IAPService.instance.purchase(_selectedPlan);
    if (!mounted) return;

    if (result.success) {
      await ref
          .read(subscriptionProvider.notifier)
          .activatePaid(
            plan: _selectedPlan,
            paymentMethod: PaymentMethod.store,
            transactionRef:
                result.transactionId ?? IAPProducts.idForPlan(_selectedPlan),
          );
      if (mounted) {
        Navigator.pop(context);
        _showSuccess();
      }
    } else {
      _showError(result.error ?? 'Purchase failed');
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    try {
      final result = await IAPService.instance.restorePurchases();
      if (!mounted) return;

      if (!result.success || result.productId == null) {
        _showError(result.error ?? 'No previous purchases found');
        return;
      }

      final plan = IAPProducts.planForId(result.productId!);
      if (plan == null) {
        _showError('No active Personal Haven subscription found');
        return;
      }

      await ref
          .read(subscriptionProvider.notifier)
          .activatePaid(
            plan: plan,
            paymentMethod: PaymentMethod.store,
            transactionRef: result.transactionId ?? result.productId!,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription restored successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Subscription activated! Enjoy Personal Haven.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _storeButtonLabel(SubscriptionPlan plan) {
    final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
    return 'Subscribe with $storeName — ${Subscription.labelFor(plan)}';
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Personal Haven Premium'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active subscription banner
            if (subState.active != null && subState.isPremium)
              _ActiveBanner(sub: subState.active!)
            else ...[
              // Hero
              _HeroCard(),
              const SizedBox(height: 24),

              // Plan selector
              Text(
                'Choose a Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                plan: SubscriptionPlan.yearly,
                selected: _selectedPlan == SubscriptionPlan.yearly,
                badge: 'Best Value',
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.yearly),
              ),
              const SizedBox(height: 10),
              _PlanCard(
                plan: SubscriptionPlan.monthly,
                selected: _selectedPlan == SubscriptionPlan.monthly,
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.monthly),
              ),
              const SizedBox(height: 10),
              _PlanCard(
                plan: SubscriptionPlan.weekly,
                selected: _selectedPlan == SubscriptionPlan.weekly,
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.weekly),
              ),
              const SizedBox(height: 16),

              _StoreBillingNote(),
              const SizedBox(height: 16),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _storeButtonLabel(_selectedPlan),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: TextButton.icon(
                  onPressed: _isRestoring ? null : _restorePurchases,
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore, size: 18),
                  label: const Text('Restore Purchases'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Features list
              _FeaturesList(),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF2D3E40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.spa, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text(
            'Unlock Your Full Haven',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Journal, mood tracking, goals, budget, food diary, calendar — all in one safe space.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : context.colors.divider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _planName(plan),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _planSubtitle(plan),
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'KES ${Subscription.priceFor(plan).toInt()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _planName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return 'Weekly';
      case SubscriptionPlan.monthly:
        return 'Monthly';
      case SubscriptionPlan.yearly:
        return 'Yearly';
      case SubscriptionPlan.free:
        return 'Free Trial';
    }
  }

  String _planSubtitle(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return 'KES 30 / week';
      case SubscriptionPlan.monthly:
        return 'KES 100 / month';
      case SubscriptionPlan.yearly:
        return 'KES 800 / year';
      case SubscriptionPlan.free:
        return '7 days free';
    }
  }
}

class _StoreBillingNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
    final icon = Platform.isIOS ? Icons.apple : Icons.shop_outlined;
    final manageText = Platform.isIOS
        ? 'Manage or cancel in Apple ID Subscriptions.'
        : 'Manage or cancel in Google Play Subscriptions.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Billed through $storeName. $manageText',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  final _features = const [
    ('📓', 'Unlimited Journal Entries'),
    ('😊', 'Mood Tracking & Insights'),
    ('🎯', 'Goal Setting & Progress'),
    ('💰', 'Budget & Expense Tracker'),
    ('🥗', 'Food & Nutrition Diary'),
    ('📅', 'Calendar & Events'),
    ('✅', 'Tasks & Rituals'),
    ('🔒', 'Private & Secure'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s included',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(f.$1, style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final Subscription sub;
  const _ActiveBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF2D3E40)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Premium Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${Subscription.labelFor(sub.plan)} · ${sub.daysRemaining} days remaining',
            style: TextStyle(color: Colors.white70),
          ),
          if (sub.plan == SubscriptionPlan.free)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Free trial — subscribe to continue after expiry',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
