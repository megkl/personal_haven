import 'package:cloud_functions/cloud_functions.dart';
import 'package:personal_haven/data/models/subscription.dart';
import 'package:personal_haven/services/firestore_service.dart';

class SubscriptionRepository {
  final _fs = FirestoreService.instance;
  static const _col = 'subscriptions';

  /// Get the current active subscription for a user.
  Future<Subscription?> getActive(String userId) async {
    final snap = await _fs.query(
      userId,
      _col,
      (c) => c.where('status', isEqualTo: 'active'),
    );
    if (snap.docs.isEmpty) return null;
    final subscriptions =
        snap.docs.map((d) => Subscription.fromFirestore(d)).toList()
          ..sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
    final sub = subscriptions.first;
    return sub.isActive ? sub : null;
  }

  /// Get full subscription history.
  Future<List<Subscription>> getHistory(String userId) async {
    final snap = await _fs.query(
      userId,
      _col,
      (c) => c.orderBy('startDate', descending: true),
    );
    return snap.docs.map((d) => Subscription.fromFirestore(d)).toList();
  }

  /// Synchronize the single lifetime entitlement from Firebase Auth.
  Future<bool> hasLifetimePremium() async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('syncPremiumEntitlement');
    final result = await callable.call<Map<String, dynamic>>();
    return result.data['isLifetimePremium'] as bool? ?? false;
  }

  /// Check if the user has ever used their free trial.
  Future<bool> hasUsedTrial(String userId) async {
    final snap = await _fs.query(
      userId,
      _col,
      (c) => c.where('plan', isEqualTo: 'free').limit(1),
    );
    return snap.docs.isNotEmpty;
  }

  /// Create a free 7-day trial subscription (once per user).
  Future<Subscription> createTrial(String userId) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('startTrial');
    final result = await callable.call<Map<String, dynamic>>();
    final data = Map<String, dynamic>.from(result.data);
    final subscription = Map<String, dynamic>.from(data['subscription'] as Map);
    return Subscription.fromMap(subscription);
  }

  /// Verify an App Store or Google Play purchase on the backend, then return
  /// the subscription document written by the Cloud Function.
  Future<Subscription> verifyStorePurchase({
    required String userId,
    required SubscriptionPlan plan,
    required String productId,
    required String serverVerificationData,
    required String verificationSource,
    String? transactionId,
    String? localVerificationData,
  }) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('verifyStorePurchase');
    final result = await callable.call<Map<String, dynamic>>({
      'plan': plan.name,
      'productId': productId,
      'transactionId': transactionId,
      'verificationSource': verificationSource,
      'serverVerificationData': serverVerificationData,
      'localVerificationData': localVerificationData,
    });
    final data = Map<String, dynamic>.from(result.data);
    final subscription = Map<String, dynamic>.from(data['subscription'] as Map);
    return Subscription.fromMap(subscription);
  }
}
