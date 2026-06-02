import 'dart:async';
import 'dart:io';

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Product IDs — must match exactly what you create in:
///   App Store Connect  →  Subscriptions
///   Google Play Console →  Subscriptions
class IAPProducts {
  static const weeklyId = 'personal_haven_weekly';
  static const monthlyId = 'personal_haven_monthly';

  static const all = [weeklyId, monthlyId];
}

class IAPResult {
  final bool success;
  final String? productId;
  final String? transactionId;
  final String? error;

  IAPResult({
    required this.success,
    this.productId,
    this.transactionId,
    this.error,
  });
}

/// Wraps flutter_inapp_purchase with a clean async API.
class IAPService {
  static final IAPService instance = IAPService._();
  IAPService._();

  bool _initialized = false;
  StreamSubscription? _purchaseSub;
  StreamSubscription? _errorSub;

  // Pending purchase completer — resolves when a purchase lands
  Completer<IAPResult>? _pendingCompleter;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    await FlutterInappPurchase.instance.initialize();
    _initialized = true;
    _listenToPurchases();
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _errorSub?.cancel();
    await FlutterInappPurchase.instance.finalize();
    _initialized = false;
  }

  void _listenToPurchases() {
    _purchaseSub =
        FlutterInappPurchase.purchaseUpdated.listen((purchase) async {
      if (purchase == null) return;

      final completer = _pendingCompleter;
      _pendingCompleter = null;

      // Finish the transaction so the store doesn't keep prompting
      await FlutterInappPurchase.instance.finishTransaction(purchase);

      completer?.complete(IAPResult(
        success: true,
        productId: purchase.productId,
        transactionId: purchase.transactionId,
      ));
    });

    _errorSub = FlutterInappPurchase.purchaseError.listen((error) {
      final completer = _pendingCompleter;
      _pendingCompleter = null;
      completer?.complete(IAPResult(
        success: false,
        error: error?.message ?? 'Purchase failed',
      ));
    });
  }

  // ── Products ──────────────────────────────────────────────────────────────

  /// Fetch product details from the store.
  Future<List<IAPItem>> getProducts() async {
    await initialize();
    try {
      // Subscriptions use getSubscriptions on both platforms
      final items = await FlutterInappPurchase.instance
          .getSubscriptions(IAPProducts.all);
      return items ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  /// Initiate a subscription purchase. Returns an [IAPResult].
  Future<IAPResult> purchase(String productId) async {
    await initialize();

    if (_pendingCompleter != null) {
      return IAPResult(
          success: false, error: 'Another purchase is already in progress');
    }

    _pendingCompleter = Completer<IAPResult>();

    try {
      await FlutterInappPurchase.instance.requestSubscription(productId);
    } catch (e) {
      _pendingCompleter = null;
      return IAPResult(success: false, error: e.toString());
    }

    // Wait up to 5 minutes for the purchase to complete
    return _pendingCompleter!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pendingCompleter = null;
        return IAPResult(success: false, error: 'Purchase timed out');
      },
    );
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Restore previous purchases (required by App Store guidelines).
  Future<List<PurchasedItem>> restorePurchases() async {
    await initialize();
    try {
      final items =
          await FlutterInappPurchase.instance.getAvailablePurchases();
      return items ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool get isAvailable => Platform.isIOS || Platform.isAndroid;
}
