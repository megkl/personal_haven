import 'package:cloud_functions/cloud_functions.dart';
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
      var active = await _repo.getActive(targetUserId);
      active ??= await _createMissingTrial(targetUserId);

      // Publish ordinary access immediately. Lifetime access is an exceptional
      // override, so its callable must never delay or hide a valid trial.
      state = SubscriptionState(active: active, isLoading: false);

      try {
        final premiumOverride = await _repo.hasLifetimePremium();
        if (!ref.mounted) return;
        state = SubscriptionState(
          active: active,
          premiumOverride: premiumOverride,
          isLoading: false,
        );
      } catch (_) {
        // Firestore remains the source of truth for regular subscriptions.
      }

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

  /// Recovers accounts whose one-time trial was not created during sign-in,
  /// for example after a temporary network or App Check failure. The backend
  /// remains authoritative and rejects any attempt to receive a second trial.
  Future<Subscription?> _createMissingTrial(String userId) async {
    final hasUsedTrial = await _repo.hasUsedTrial(userId);
    if (hasUsedTrial) return null;
    return _repo.createTrial(userId);
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
  Future<bool> activatePaid({
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
      if (!ref.mounted) return false;
      state = SubscriptionState(active: sub, isLoading: false);
      final notificationPrefs = ref.read(notificationProvider);
      if (notificationPrefs.masterEnabled &&
          notificationPrefs.subscriptionAlerts) {
        // Schedule expiry reminders for the new subscription
        await NotificationService.instance.scheduleSubscriptionReminders(
          sub.expiryDate,
        );
      }
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: _purchaseErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> refresh() => _load();

  void clearError() => state = state.copyWith(error: null);

  String _purchaseErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return 'Please sign in again, then restore your purchase.';
        case 'permission-denied':
          return 'This purchase is linked to a different account.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Purchase verification is temporarily unavailable. '
              'Please try again.';
        case 'failed-precondition':
          return error.message ??
              'Google Play could not verify this subscription.';
      }
    }
    return 'The purchase could not be verified. Please try Restore purchases.';
  }
}

/// Convenience — true when user has an active paid/trial subscription.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium;
});
