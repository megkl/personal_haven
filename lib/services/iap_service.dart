import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:personal_haven/data/models/subscription.dart';

class IAPProducts {
  static const weeklyId = 'personal_haven_weekly';
  static const monthlyId = 'personal_haven_monthly';
  static const yearlyId = 'personal_haven_yearly';

  static const all = <String>{weeklyId, monthlyId, yearlyId};

  static String idForPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return weeklyId;
      case SubscriptionPlan.monthly:
        return monthlyId;
      case SubscriptionPlan.yearly:
        return yearlyId;
      case SubscriptionPlan.free:
        throw ArgumentError('Free trial is not a store product');
    }
  }

  static SubscriptionPlan? planForId(String productId) {
    switch (productId) {
      case weeklyId:
        return SubscriptionPlan.weekly;
      case monthlyId:
        return SubscriptionPlan.monthly;
      case yearlyId:
        return SubscriptionPlan.yearly;
      default:
        return null;
    }
  }
}

class IAPResult {
  const IAPResult({
    required this.success,
    this.productId,
    this.transactionId,
    this.error,
  });

  final bool success;
  final String? productId;
  final String? transactionId;
  final String? error;
}

class IAPService {
  static final IAPService instance = IAPService._();
  IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<IAPResult>? _pendingPurchase;
  bool _initialized = false;

  static bool get isStorePlatform => Platform.isIOS || Platform.isAndroid;

  Future<bool> initialize() async {
    if (!isStorePlatform) return false;
    if (_initialized) return true;

    final available = await _iap.isAvailable();
    if (!available) return false;

    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdates);
    _initialized = true;
    return true;
  }

  Future<List<ProductDetails>> getProducts() async {
    final ready = await initialize();
    if (!ready) return [];

    final response = await _iap.queryProductDetails(IAPProducts.all);
    return response.productDetails;
  }

  Future<IAPResult> purchase(SubscriptionPlan plan) async {
    final ready = await initialize();
    if (!ready) {
      return const IAPResult(
        success: false,
        error: 'Store billing unavailable',
      );
    }
    if (_pendingPurchase != null) {
      return const IAPResult(
        success: false,
        error: 'Another purchase is already in progress',
      );
    }

    final productId = IAPProducts.idForPlan(plan);
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      return IAPResult(
        success: false,
        error: 'Product not found in store: $productId',
      );
    }

    _pendingPurchase = Completer<IAPResult>();
    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _pendingPurchase = null;
      return const IAPResult(success: false, error: 'Purchase could not start');
    }

    return _pendingPurchase!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pendingPurchase = null;
        return const IAPResult(success: false, error: 'Purchase timed out');
      },
    );
  }

  Future<IAPResult> restorePurchases() async {
    final ready = await initialize();
    if (!ready) {
      return const IAPResult(
        success: false,
        error: 'Store billing unavailable',
      );
    }
    if (_pendingPurchase != null) {
      return const IAPResult(
        success: false,
        error: 'Another purchase is already in progress',
      );
    }

    _pendingPurchase = Completer<IAPResult>();
    await _iap.restorePurchases();
    return _pendingPurchase!.future.timeout(
      const Duration(minutes: 1),
      onTimeout: () {
        _pendingPurchase = null;
        return const IAPResult(
          success: false,
          error: 'No previous purchases found',
        );
      },
    );
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _pendingPurchase = null;
    _initialized = false;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      final completer = _pendingPurchase;
      if (completer == null || completer.isCompleted) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _pendingPurchase = null;
          completer.complete(
            IAPResult(
              success: true,
              productId: purchase.productID,
              transactionId:
                  purchase.purchaseID ??
                  purchase.verificationData.serverVerificationData,
            ),
          );
          break;
        case PurchaseStatus.error:
          _pendingPurchase = null;
          completer.complete(
            IAPResult(
              success: false,
              error: purchase.error?.message ?? 'Purchase failed',
            ),
          );
          break;
        case PurchaseStatus.canceled:
          _pendingPurchase = null;
          completer.complete(
            const IAPResult(success: false, error: 'Purchase cancelled'),
          );
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }
}
