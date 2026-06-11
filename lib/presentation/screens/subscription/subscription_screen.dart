import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/subscription.dart';
import 'package:personal_haven/providers/subscription_provider.dart';
import 'package:personal_haven/services/iap_service.dart';
import 'package:personal_haven/services/mpesa_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  final _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      switch (_selectedMethod) {
        case PaymentMethod.mpesa:
          await _handleMpesa();
          break;
        case PaymentMethod.card:
          _showCardInfo();
          break;
        case PaymentMethod.usdt:
          _showUsdtInfo();
          break;
        case PaymentMethod.appStore:
          //await _handleIAP();
          break;
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMpesa() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter your M-Pesa phone number');
      return;
    }

    // Normalise to 2547XXXXXXXX
    final normalised = _normalisePhone(phone);
    if (normalised == null) {
      _showError('Enter a valid Kenyan phone number (07XX or 2547XX)');
      return;
    }

    final amount = Subscription.priceFor(_selectedPlan);
    final result = await MpesaService.instance.stkPush(
      phone: normalised,
      amount: amount,
      accountRef: 'PersonalHaven',
      description: 'Personal Haven ${Subscription.labelFor(_selectedPlan)}',
    );

    if (!mounted) return;

    if (result.success && result.checkoutRequestId != null) {
      _showMpesaWaiting(result.checkoutRequestId!);
    } else {
      _showError(result.error ?? 'M-Pesa request failed');
    }
  }

  // Future<void> _handleIAP() async {
  //   final productId = _selectedPlan == SubscriptionPlan.monthly
  //       ? IAPProducts.monthlyId
  //       : IAPProducts.weeklyId;

  //   final result = await IAPService.instance.purchase(productId);
  //   if (!mounted) return;

  //   if (result.success) {
  //     await ref.read(subscriptionProvider.notifier).activatePaid(
  //           plan: _selectedPlan,
  //           paymentMethod: PaymentMethod.appStore,
  //           transactionRef: result.transactionId ?? productId,
  //         );
  //     if (mounted) {
  //       Navigator.pop(context);
  //       _showSuccess();
  //     }
  //   } else {
  //     _showError(result.error ?? 'Purchase failed');
  //   }
  // }

  // Future<void> _restorePurchases() async {
  //   setState(() => _isRestoring = true);
  //   try {
  //     final purchases = await IAPService.instance.restorePurchases();
  //     if (!mounted) return;

  //     if (purchases.isEmpty) {
  //       _showError('No previous purchases found');
  //       return;
  //     }

  //     // Find the most recent active subscription
  //     final monthly = purchases.any(
  //         (p) => p.productId == IAPProducts.monthlyId);
  //     final weekly =
  //         purchases.any((p) => p.productId == IAPProducts.weeklyId);

  //     final plan = monthly
  //         ? SubscriptionPlan.monthly
  //         : weekly
  //             ? SubscriptionPlan.weekly
  //             : null;

  //     if (plan == null) {
  //       _showError('No active subscription found to restore');
  //       return;
  //     }

  //     final latest = purchases.firstWhere(
  //         (p) => p.productId == IAPProducts.monthlyId || p.productId == IAPProducts.weeklyId);

  //     await ref.read(subscriptionProvider.notifier).activatePaid(
  //           plan: plan,
  //           paymentMethod: PaymentMethod.appStore,
  //           transactionRef: latest.transactionId ?? 'restored',
  //         );

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text('✅ Subscription restored successfully'),
  //         backgroundColor: AppColors.primary,
  //       ));
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isRestoring = false);
  //   }
  // }

  void _showMpesaWaiting(String checkoutRequestId) {    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MpesaWaitingDialog(
        checkoutRequestId: checkoutRequestId,
        plan: _selectedPlan,
        onSuccess: (ref) async {
          await ref.read(subscriptionProvider.notifier).activatePaid(
                plan: _selectedPlan,
                paymentMethod: PaymentMethod.mpesa,
                transactionRef: checkoutRequestId,
              );
          if (mounted) {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // close subscription screen
            _showSuccess();
          }
        },
        onFailed: () {
          if (mounted) _showError('Payment was not completed. Please try again.');
        },
      ),
    );
  }

  void _showCardInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Card Payment'),
        content: const Text(
          'Card payments are processed via our secure payment gateway.\n\n'
          'You will be redirected to complete your payment.\n\n'
          'Coming soon — contact support@personalhaven.app to pay by card.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUsdtInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pay with USDT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send USDT (TRC-20) to:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'YOUR_USDT_WALLET_ADDRESS',
                style: TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount: \$${(Subscription.priceFor(_selectedPlan) / 130).toStringAsFixed(2)} USDT',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'After sending, email your transaction hash to:\nsupport@personalhaven.app',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🎉 Subscription activated! Enjoy Personal Haven.'),
      backgroundColor: AppColors.primary,
    ));
  }

  String? _normalisePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (phone.startsWith('07') && phone.length == 10) {
      return '254${phone.substring(1)}';
    }
    if (phone.startsWith('2547') && phone.length == 12) return phone;
    if (phone.startsWith('+2547') && phone.length == 13) {
      return phone.substring(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Haven Premium'),
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
              const Text('Choose a Plan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _PlanCard(
                plan: SubscriptionPlan.monthly,
                selected: _selectedPlan == SubscriptionPlan.monthly,
                badge: 'Best Value',
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
              const SizedBox(height: 24),

              // Payment method
              const Text('Payment Method',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              // _PaymentMethodSelector(
              //   selected: _selectedMethod,
              //   onChanged: (m) => setState(() => _selectedMethod = m),
              // ),
              const SizedBox(height: 16),

              // App Store / Play Store note
              if (_selectedMethod == PaymentMethod.appStore) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Platform.isIOS ? Icons.apple : Icons.android,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Platform.isIOS
                              ? 'Billed through your Apple ID. Manage in Settings → Apple ID → Subscriptions.'
                              : 'Billed through Google Play. Manage in Play Store → Subscriptions.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Phone field for M-Pesa
              if (_selectedMethod == PaymentMethod.mpesa) ...[                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    hintText: '07XX XXX XXX',
                    prefixIcon:
                        const Icon(Icons.phone, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will receive an STK push on your phone to confirm payment.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
              ],

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
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Subscribe — ${Subscription.labelFor(_selectedPlan)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // // Restore purchases (App Store requirement)
              // if (IAPService.isAvailable)
              //   Center(
              //     child: TextButton.icon(
              //       onPressed: _isRestoring ? null : _restorePurchases,
              //       icon: _isRestoring
              //           ? const SizedBox(
              //               width: 14,
              //               height: 14,
              //               child: CircularProgressIndicator(strokeWidth: 2))
              //           : const Icon(Icons.restore, size: 18),
              //       label: const Text('Restore Purchases'),
              //       style: TextButton.styleFrom(
              //           foregroundColor: AppColors.textSecondary),
              //     ),
              //   ),

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
          Text('Unlock Your Full Haven',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
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
          color: Colors.white,
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
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            Radio<SubscriptionPlan>(
              value: plan,
              groupValue: selected ? plan : null,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan == SubscriptionPlan.monthly
                            ? 'Monthly'
                            : 'Weekly',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    plan == SubscriptionPlan.monthly
                        ? 'KES 100 / month'
                        : 'KES 30 / week',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              plan == SubscriptionPlan.monthly ? 'KES 100' : 'KES 30',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentMethodSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        //if (IAPService.isAvailable)
          _MethodChip(
            label: Platform.isIOS ? 'App Store' : 'Play Store',
            icon: Platform.isIOS ? '🍎' : '▶',
            selected: selected == PaymentMethod.appStore,
            onTap: () => onChanged(PaymentMethod.appStore),
          ),
        _MethodChip(
          label: 'M-Pesa',
          icon: '📱',
          selected: selected == PaymentMethod.mpesa,
          onTap: () => onChanged(PaymentMethod.mpesa),
        ),
        _MethodChip(
          label: 'Card',
          icon: '💳',
          selected: selected == PaymentMethod.card,
          onTap: () => onChanged(PaymentMethod.card),
        ),
        _MethodChip(
          label: 'USDT',
          icon: '₮',
          selected: selected == PaymentMethod.usdt,
          onTap: () => onChanged(PaymentMethod.usdt),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What\'s included',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(f.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(f.$2,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ],
                ),
              )),
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
              Text('Premium Active',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${Subscription.labelFor(sub.plan)} · ${sub.daysRemaining} days remaining',
            style: const TextStyle(color: Colors.white70),
          ),
          if (sub.plan == SubscriptionPlan.free)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Free trial — subscribe to continue after expiry',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ── M-Pesa waiting dialog ─────────────────────────────────────────────────────

class _MpesaWaitingDialog extends ConsumerStatefulWidget {
  final String checkoutRequestId;
  final SubscriptionPlan plan;
  final void Function(WidgetRef ref) onSuccess;
  final VoidCallback onFailed;

  const _MpesaWaitingDialog({
    required this.checkoutRequestId,
    required this.plan,
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  ConsumerState<_MpesaWaitingDialog> createState() =>
      _MpesaWaitingDialogState();
}

class _MpesaWaitingDialogState extends ConsumerState<_MpesaWaitingDialog> {
  Timer? _timer;
  int _attempts = 0;
  String _status = 'Waiting for payment confirmation…';

  @override
  void initState() {
    super.initState();
    // Poll every 5 seconds, up to 12 times (1 minute)
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    _attempts++;
    final result = await MpesaService.instance
        .queryStatus(widget.checkoutRequestId);

    if (!mounted) return;

    if (result.status == 'success') {
      _timer?.cancel();
      widget.onSuccess(ref);
    } else if (_attempts >= 12) {
      _timer?.cancel();
      Navigator.pop(context);
      widget.onFailed();
    } else {
      setState(() => _status = 'Checking payment… ($_attempts/12)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Check your phone for the M-Pesa prompt and enter your PIN.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(_status,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
