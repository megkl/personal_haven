import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/subscription.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class SubscriptionRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'subscriptions';

  /// Get the current active subscription for a user.
  Future<Subscription?> getActive(String userId) async {
    final snap = await _fs.query(
      userId,
      _col,
      (c) => c
          .where('status', isEqualTo: 'active')
          .orderBy('expiryDate', descending: true)
          .limit(1),
    );
    if (snap.docs.isEmpty) return null;
    final sub = Subscription.fromFirestore(snap.docs.first);
    // Auto-expire if past expiry
    if (!sub.isActive) {
      await _expire(userId, sub.id);
      return null;
    }
    return sub;
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

  /// Check if the user has ever used their free trial.
  Future<bool> hasUsedTrial(String userId) async {
    final snap = await _fs.query(
      userId,
      _col,
      (c) => c.where('plan', isEqualTo: 'free').limit(1),
    );
    return snap.docs.isNotEmpty;
  }

  /// Create a free 30-day trial subscription (once per user).
  Future<Subscription> createTrial(String userId) async {
    final now = DateTime.now();
    final sub = Subscription(
      id: _uuid.v4(),
      userId: userId,
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.active,
      startDate: now,
      expiryDate: now.add(Subscription.durationFor(SubscriptionPlan.free)),
      amountPaid: 0,
      isTrialUsed: true,
    );
    await _fs.set(userId, _col, sub.id, sub.toFirestore());
    await _updateUserPremium(userId, true);
    return sub;
  }

  /// Create a paid subscription after successful payment.
  Future<Subscription> createPaid({
    required String userId,
    required SubscriptionPlan plan,
    required PaymentMethod paymentMethod,
    required String transactionRef,
  }) async {
    final now = DateTime.now();
    final sub = Subscription(
      id: _uuid.v4(),
      userId: userId,
      plan: plan,
      status: SubscriptionStatus.active,
      startDate: now,
      expiryDate: now.add(Subscription.durationFor(plan)),
      paymentMethod: paymentMethod,
      transactionRef: transactionRef,
      amountPaid: Subscription.priceFor(plan),
    );
    await _fs.set(userId, _col, sub.id, sub.toFirestore());
    await _updateUserPremium(userId, true);
    return sub;
  }

  /// Mark a subscription as expired.
  Future<void> _expire(String userId, String subId) async {
    await _fs.update(userId, _col, subId, {'status': 'expired'});
    await _updateUserPremium(userId, false);
  }

  /// Cancel a subscription.
  Future<void> cancel(String userId, String subId) async {
    await _fs.update(userId, _col, subId, {'status': 'cancelled'});
    await _updateUserPremium(userId, false);
  }

  /// Sync isPremium on the user profile document.
  Future<void> _updateUserPremium(String userId, bool isPremium) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'isPremium': isPremium});
  }
}
