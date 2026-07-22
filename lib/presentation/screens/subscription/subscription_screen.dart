import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
  bool _isLoadingCatalog = true;
  IAPCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await IAPService.instance.getCatalog();
    if (!mounted) return;

    final selectedProduct = catalog.productForPlan(_selectedPlan);
    SubscriptionPlan? fallbackPlan;
    for (final plan in <SubscriptionPlan>[
      SubscriptionPlan.monthly,
      SubscriptionPlan.yearly,
      SubscriptionPlan.weekly,
    ]) {
      if (catalog.isPlanAvailable(plan)) {
        fallbackPlan = plan;
        break;
      }
    }

    setState(() {
      _catalog = catalog;
      _isLoadingCatalog = false;
      if (selectedProduct == null && fallbackPlan != null) {
        _selectedPlan = fallbackPlan;
      }
    });
  }

  Future<void> _subscribe() async {
    if (_isProcessing) return;
    final catalog = _catalog;
    if (catalog == null || !catalog.isPlanAvailable(_selectedPlan)) {
      _showError('This subscription is not available in the store yet.');
      return;
    }
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
      final activated = await ref
          .read(subscriptionProvider.notifier)
          .activatePaid(
            plan: _selectedPlan,
            transactionRef:
                result.transactionId ?? IAPProducts.idForPlan(_selectedPlan),
            productId: result.productId ?? IAPProducts.idForPlan(_selectedPlan),
            serverVerificationData: result.serverVerificationData ?? '',
            localVerificationData: result.localVerificationData,
            verificationSource: result.verificationSource ?? '',
          );
      if (!activated) {
        _showError(
          ref.read(subscriptionProvider).error ??
              'The store purchase could not be verified.',
        );
        return;
      }
      await IAPService.instance.completeVerifiedPurchase();
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

      final activated = await ref
          .read(subscriptionProvider.notifier)
          .activatePaid(
            plan: plan,
            transactionRef: result.transactionId ?? result.productId!,
            productId: result.productId!,
            serverVerificationData: result.serverVerificationData ?? '',
            localVerificationData: result.localVerificationData,
            verificationSource: result.verificationSource ?? '',
          );
      if (!activated) {
        _showError(
          ref.read(subscriptionProvider).error ??
              'The restored purchase could not be verified.',
        );
        return;
      }
      await IAPService.instance.completeVerifiedPurchase();
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
    final product = _catalog?.productForPlan(plan);
    return product == null ? 'Subscribe' : 'Subscribe — ${product.price}';
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final catalog = _catalog;
    final selectedProduct = catalog?.productForPlan(_selectedPlan);
    final active = subState.active;
    final isTrial = active?.plan == SubscriptionPlan.free && subState.isPremium;
    final showPlanOptions = !subState.hasFullAccess || isTrial;
    final canSubscribe =
        !_isProcessing &&
        !_isLoadingCatalog &&
        catalog?.isAvailable == true &&
        selectedProduct != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeading(context),
                  const SizedBox(height: 18),
                  if (subState.hasFullAccess)
                    _ActiveBanner(
                      sub: active,
                      lifetimeAccess: subState.premiumOverride,
                    )
                  else
                    const _HeroCard(),
                  const SizedBox(height: 18),
                  const _FeaturesList(),
                  if (showPlanOptions) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.colors.cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: context.colors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTrial ? 'Continue with premium' : 'Choose a plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Prices and plan names come directly from ${Platform.isIOS ? 'the App Store' : 'Google Play'}.',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingCatalog)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 14),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          _PlanCard(
                            plan: SubscriptionPlan.yearly,
                            selected: _selectedPlan == SubscriptionPlan.yearly,
                            product: catalog?.productForPlan(
                              SubscriptionPlan.yearly,
                            ),
                            available:
                                catalog?.isPlanAvailable(
                                  SubscriptionPlan.yearly,
                                ) ??
                                false,
                            badge: 'Best value',
                            onTap: () => setState(
                              () => _selectedPlan = SubscriptionPlan.yearly,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PlanCard(
                            plan: SubscriptionPlan.monthly,
                            selected: _selectedPlan == SubscriptionPlan.monthly,
                            product: catalog?.productForPlan(
                              SubscriptionPlan.monthly,
                            ),
                            available:
                                catalog?.isPlanAvailable(
                                  SubscriptionPlan.monthly,
                                ) ??
                                false,
                            onTap: () => setState(
                              () => _selectedPlan = SubscriptionPlan.monthly,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PlanCard(
                            plan: SubscriptionPlan.weekly,
                            selected: _selectedPlan == SubscriptionPlan.weekly,
                            product: catalog?.productForPlan(
                              SubscriptionPlan.weekly,
                            ),
                            available:
                                catalog?.isPlanAvailable(
                                  SubscriptionPlan.weekly,
                                ) ??
                                false,
                            onTap: () => setState(
                              () => _selectedPlan = SubscriptionPlan.weekly,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!_isLoadingCatalog &&
                        (catalog?.isAvailable != true ||
                            catalog?.products.isEmpty == true))
                      _StoreIssueNotice(
                        message:
                            catalog?.error ??
                            'Store products are not available yet. Check your store product configuration.',
                        onRetry: _loadCatalog,
                      ),
                    if (!_isLoadingCatalog &&
                        catalog?.notFoundIds.isNotEmpty == true)
                      _MissingProductsNotice(ids: catalog!.notFoundIds),
                    const _StoreBillingNote(),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: canSubscribe ? _subscribe : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isProcessing || _isLoadingCatalog
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _storeButtonLabel(_selectedPlan),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed:
                            (_isRestoring || catalog?.isAvailable != true)
                            ? null
                            : _restorePurchases,
                        icon: _isRestoring
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Restore purchases'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeading(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to profile',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Haven Premium',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the plan that fits your haven',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF319E96), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PremiumHeroIcon(),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock your full haven',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'More space to reflect, plan, and care for your wellbeing—all in one safe place.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeroIcon extends StatelessWidget {
  const _PremiumHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final ProductDetails? product;
  final bool available;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.product,
    required this.available,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = available
        ? context.colors.textPrimary
        : context.colors.textSecondary.withValues(alpha: 0.65);

    return GestureDetector(
      onTap: available ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: available
              ? context.colors.cardColor
              : context.colors.cardColor2.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected && available
                ? AppColors.primary
                : context.colors.divider.withValues(alpha: 0.35),
            width: selected && available ? 2 : 1,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : context.colors.divider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product?.title ?? _planName(plan),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
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
                  const SizedBox(height: 5),
                  Text(
                    available
                        ? product?.price ?? 'Store price unavailable'
                        : 'Not available in store yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: available
                          ? AppColors.primary
                          : context.colors.divider,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _planSubtitle(plan),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
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
        return 'Billed every week. Cancel anytime.';
      case SubscriptionPlan.monthly:
        return 'Billed every month. Cancel anytime.';
      case SubscriptionPlan.yearly:
        return 'Billed every year. Cancel anytime.';
      case SubscriptionPlan.free:
        return '7 days free';
    }
  }
}

class _StoreBillingNote extends StatelessWidget {
  const _StoreBillingNote();

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
        color: AppColors.info.withValues(alpha: context.isDark ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(icon, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Billed through $storeName. $manageText',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreIssueNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StoreIssueNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MissingProductsNotice extends StatelessWidget {
  final Set<String> ids;

  const _MissingProductsNotice({required this.ids});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Missing store products: ${ids.join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  const _FeaturesList();

  final _features = const [
    ('📓', 'Ask Haven Chat Assistant'),
    ('📓', 'Unlimited Journal Entries'),
    ('😊', 'Mood Tracking & Insights'),
    ('🎯', 'Goal Setting & Progress'),
    ('💰', 'Budget & Expense Tracker'),
    //('🥗', 'Food & Nutrition Diary'),
    ('📅', 'Calendar & Events'),
    ('✅', 'Tasks, Shopping List Creation'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.divider),
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
          const SizedBox(height: 14),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(f.$1, style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textPrimary,
                      ),
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
  final Subscription? sub;
  final bool lifetimeAccess;

  const _ActiveBanner({required this.sub, required this.lifetimeAccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF319E96), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Your haven is fully unlocked',
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
            lifetimeAccess && sub == null
                ? 'Lifetime premium access'
                : sub == null
                ? 'Premium access'
                : '${_planName(sub!.plan)} · ${sub!.daysRemaining} days remaining',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.84)),
          ),
          if (sub?.plan == SubscriptionPlan.free)
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

  String _planName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return 'Weekly subscription';
      case SubscriptionPlan.monthly:
        return 'Monthly subscription';
      case SubscriptionPlan.yearly:
        return 'Yearly subscription';
      case SubscriptionPlan.free:
        return 'Free trial';
    }
  }
}
