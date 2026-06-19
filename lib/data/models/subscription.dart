import 'package:equatable/equatable.dart';

enum SubscriptionPlan { free, weekly, monthly, yearly }

enum SubscriptionStatus { active, expired, cancelled, pending }

enum PaymentMethod { store }

class Subscription extends Equatable {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime expiryDate;
  final PaymentMethod? paymentMethod;
  final String? transactionRef;
  final double amountPaid;
  final String currency;
  final bool isTrialUsed;

  const Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    this.paymentMethod,
    this.transactionRef,
    this.amountPaid = 0,
    this.currency = 'KES',
    this.isTrialUsed = false,
  });

  bool get isActive =>
      status == SubscriptionStatus.active && expiryDate.isAfter(DateTime.now());

  int get daysRemaining =>
      expiryDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  static double priceFor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return 30.0;
      case SubscriptionPlan.monthly:
        return 100.0;
      case SubscriptionPlan.yearly:
        return 800.0;
      case SubscriptionPlan.free:
        return 0.0;
    }
  }

  static String labelFor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return 'Weekly — KES 30';
      case SubscriptionPlan.monthly:
        return 'Monthly — KES 100';
      case SubscriptionPlan.yearly:
        return 'Yearly — KES 800';
      case SubscriptionPlan.free:
        return 'Free Trial';
    }
  }

  static Duration durationFor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return const Duration(days: 7);
      case SubscriptionPlan.monthly:
        return const Duration(days: 30);
      case SubscriptionPlan.yearly:
        return const Duration(days: 365);
      case SubscriptionPlan.free:
        return const Duration(days: 7);
    }
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'plan': plan.name,
    'status': status.name,
    'startDate': startDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'paymentMethod': paymentMethod?.name,
    'transactionRef': transactionRef,
    'amountPaid': amountPaid,
    'currency': currency,
    'isTrialUsed': isTrialUsed,
  };

  factory Subscription.fromFirestore(dynamic doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: d['userId'] as String,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == d['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => SubscriptionStatus.expired,
      ),
      startDate: DateTime.parse(d['startDate'] as String),
      expiryDate: DateTime.parse(d['expiryDate'] as String),
      paymentMethod: d['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == d['paymentMethod'],
              orElse: () => PaymentMethod.store,
            )
          : null,
      transactionRef: d['transactionRef'] as String?,
      amountPaid: (d['amountPaid'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'KES',
      isTrialUsed: d['isTrialUsed'] as bool? ?? false,
    );
  }

  Subscription copyWith({
    SubscriptionStatus? status,
    DateTime? expiryDate,
    String? transactionRef,
    PaymentMethod? paymentMethod,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      plan: plan,
      status: status ?? this.status,
      startDate: startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionRef: transactionRef ?? this.transactionRef,
      amountPaid: amountPaid,
      currency: currency,
      isTrialUsed: isTrialUsed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    plan,
    status,
    startDate,
    expiryDate,
    isTrialUsed,
  ];
}
