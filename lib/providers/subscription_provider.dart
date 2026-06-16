import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/subscription.dart';
import 'package:personal_haven/data/repositories/subscription_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/providers/notification_provider.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'subscription_provider.g.dart';

class SubscriptionState {
  final Subscription? active;
  final bool isLoading;
  final String? error;

  const SubscriptionState({this.active, this.isLoading = true, this.error});

  bool get isPremium => active?.isActive ?? false;

  SubscriptionState copyWith({
    Subscription? active,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      active: active ?? this.active,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  final SubscriptionRepository _repo = SubscriptionRepository();

  String get _userId => ref.watch(currentUserIdProvider);

  @override
  SubscriptionState build() {
    Future.microtask(_load);
    return SubscriptionState();
  }

  Future<void> _load() async {
    if (_userId.isEmpty) {
      state = const SubscriptionState(isLoading: false);
      return;
    }
    try {
      final previousActive = state.active;
      final active = await _repo.getActive(_userId);
      state = SubscriptionState(active: active, isLoading: false);
      final notificationPrefs = ref.read(notificationProvider);
      final subscriptionNotificationsEnabled =
          notificationPrefs.masterEnabled &&
          notificationPrefs.subscriptionAlerts;

      // Schedule expiry reminders whenever we load an active subscription
      if (subscriptionNotificationsEnabled &&
          active != null &&
          active.isActive) {
        await NotificationService.instance.scheduleSubscriptionReminders(
          active.expiryDate,
        );
      } else if (subscriptionNotificationsEnabled &&
          active == null &&
          previousActive != null) {
        // Was active, now expired
        await NotificationService.instance.notifySubscriptionExpired();
      }
    } catch (e) {
      state = SubscriptionState(isLoading: false, error: e.toString());
    }
  }

  /// Activate the free trial (called once on first sign-up).
  Future<bool> activateTrial() async {
    try {
      final alreadyUsed = await _repo.hasUsedTrial(_userId);
      if (alreadyUsed) return false;
      final sub = await _repo.createTrial(_userId);
      state = state.copyWith(active: sub, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Called after a successful payment to activate the subscription.
  Future<void> activatePaid({
    required SubscriptionPlan plan,
    required PaymentMethod paymentMethod,
    required String transactionRef,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final sub = await _repo.createPaid(
        userId: _userId,
        plan: plan,
        paymentMethod: paymentMethod,
        transactionRef: transactionRef,
      );
      state = SubscriptionState(active: sub, isLoading: false);
      final notificationPrefs = ref.read(notificationProvider);
      if (notificationPrefs.masterEnabled &&
          notificationPrefs.subscriptionAlerts) {
        // Schedule expiry reminders for the new subscription
        await NotificationService.instance.scheduleSubscriptionReminders(
          sub.expiryDate,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  void clearError() => state = state.copyWith(error: null);
}

/// Convenience — true when user has an active paid/trial subscription.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium;
});
