import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/api/api_client.dart';

const _kProductIds = <String>{
  'jiuflow.founder.monthly',
  'jiuflow.regular.monthly',
  'jiuflow.pro.monthly',
};

class IapService {
  static final IapService _instance = IapService._();
  factory IapService() => _instance;
  IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = [];
  bool available = false;

  /// Callback when purchase succeeds
  void Function(PurchaseDetails)? onPurchaseSuccess;
  void Function(String)? onPurchaseError;

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[IAP] Store not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => debugPrint('[IAP] Stream error: $e'),
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_kProductIds);
    if (response.error != null) {
      debugPrint('[IAP] Query error: ${response.error}');
      return;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IAP] Not found: ${response.notFoundIDs}');
    }
    products = response.productDetails;
    debugPrint('[IAP] Loaded ${products.length} products');
  }

  Future<void> buySubscription(String productId) async {
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint('[IAP] Purchase update: ${purchase.productID} status=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          onPurchaseError?.call(purchase.error?.message ?? '購入エラー');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          onPurchaseError?.call('購入がキャンセルされました');
          break;
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // Send receipt to server for verification
    try {
      final api = ApiClient();
      final receiptData = purchase.verificationData.serverVerificationData;
      await api.dio.post('/api/v1/subscription/verify-apple', data: {
        'receipt_data': receiptData,
        'product_id': purchase.productID,
      });
      debugPrint('[IAP] Receipt verified on server');
    } catch (e) {
      debugPrint('[IAP] Receipt verification error: $e');
    }
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    onPurchaseSuccess?.call(purchase);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
