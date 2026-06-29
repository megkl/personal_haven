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
  final bool premiumOverride;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.active,
    this.premiumOverride = false,
    this.isLoading = true,
    this.error,
  });

  bool get isPremium => (active?.isActive ?? false) || premiumOverride;
  bool get hasFullAccess => isPremium;

  SubscriptionState copyWith({
    Subscription? active,
    bool? premiumOverride,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      active: active ?? this.active,
      premiumOverride: premiumOverride ?? this.premiumOverride,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  final SubscriptionRepository _repo = SubscriptionRepository();

  String get _userId => ref.read(currentUserIdProvider);

  @override
  SubscriptionState build() {
    final userId = ref.watch(currentUserIdProvider);
    Future.microtask(() => _load(userId: userId));
    return SubscriptionState();
  }

  Future<void> _load({String? userId}) async {
    final targetUserId = userId ?? _userId;
    if (targetUserId.isEmpty) {
      state = const SubscriptionState(isLoading: false);
      return;
    }
    try {
      final previousActive = state.active;
      final premiumOverride = await _repo.hasPremiumOverride(targetUserId);
      Subscription? active;
      try {
        active = await _repo.getActive(targetUserId);
      } catch (e) {
        if (!premiumOverride) rethrow;
      }
      state = SubscriptionState(
        active: active,
        premiumOverride: premiumOverride,
        isLoading: false,
      );
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
    required String transactionRef,
    required String productId,
    required String serverVerificationData,
    required String verificationSource,
    String? localVerificationData,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final sub = await _repo.verifyStorePurchase(
        userId: _userId,
        plan: plan,
        productId: productId,
        transactionId: transactionRef,
        serverVerificationData: serverVerificationData,
        localVerificationData: localVerificationData,
        verificationSource: verificationSource,
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
