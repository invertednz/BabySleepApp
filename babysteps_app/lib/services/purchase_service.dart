import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:babysteps_app/services/mixpanel_service.dart';

/// Product IDs matching App Store Connect / Google Play Console configuration.
class ProductIds {
  static const String monthly = 'babysteps_monthly';
  static const String yearly = 'babysteps_yearly';
  static const String payforward = 'babysteps_payforward';
  static const String gift = 'babysteps_gift';

  static const Set<String> all = {monthly, yearly, payforward, gift};
}

enum PurchaseResult {
  success,
  cancelled,
  error,
  pending,
}

/// Maps a store product ID to the plan_tier value stored in Supabase.
String planTierFromProductId(String productId) {
  switch (productId) {
    case ProductIds.monthly:
      return 'monthly';
    case ProductIds.yearly:
      return 'yearly';
    case ProductIds.payforward:
      return 'payforward';
    case ProductIds.gift:
      return 'gift';
    default:
      return 'paid';
  }
}

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final MixpanelService _mixpanel = MixpanelService();

  bool _initialized = false;
  bool _storeAvailable = false;
  bool get isStoreAvailable => _storeAvailable;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Products loaded from the store, keyed by product ID.
  final Map<String, ProductDetails> _products = {};

  /// Whether we're running on a platform with real IAP (iOS or Android).
  bool get isRealPurchasesPlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Callback set by the active payment screen to receive purchase updates.
  void Function(PurchaseResult result, {String? error})? onPurchaseUpdate;

  /// Persistent callback for purchases completed outside of active screens.
  /// Set once during app initialization to update auth state.
  void Function(String productId)? onBackgroundPurchaseCompleted;

  /// Initialize the service. Call once from main.dart.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isRealPurchasesPlatform) {
      _storeAvailable = false;
      return;
    }

    final iap = InAppPurchase.instance;
    _storeAvailable = await iap.isAvailable();
    if (!_storeAvailable) return;

    _purchaseSubscription = iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _purchaseSubscription = null;
      },
      onError: (dynamic error) {
        _mixpanel.trackEvent('IAP Stream Error',
            properties: {'error': error.toString()});
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final iap = InAppPurchase.instance;
    final response = await iap.queryProductDetails(ProductIds.all);
    if (response.error != null) {
      _mixpanel.trackEvent('IAP Product Query Error',
          properties: {'error': response.error!.message});
    }
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
    for (final id in response.notFoundIDs) {
      _mixpanel.trackEvent('IAP Product Not Found', properties: {'id': id});
    }
  }

  /// Get the localized price string for a product ID. Returns null if not loaded.
  String? getLocalizedPrice(String productId) {
    return _products[productId]?.price;
  }

  /// Get the localized price or fall back to a default string.
  String displayPrice(String productId, String fallback) {
    return _products[productId]?.price ?? fallback;
  }

  /// Get all loaded products.
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  /// Initiate a purchase. On web this runs the mock flow.
  Future<PurchaseResult> buyProduct(String productId) async {
    if (!isRealPurchasesPlatform) {
      return _mockPurchase(productId);
    }

    final product = _products[productId];
    if (product == null) {
      _mixpanel.trackEvent('IAP Product Not Available',
          properties: {'product_id': productId});
      return PurchaseResult.error;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final started =
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

    if (!started) {
      return PurchaseResult.error;
    }
    // The actual result comes through the purchase stream.
    return PurchaseResult.pending;
  }

  /// Mock purchase for the web platform.
  Future<PurchaseResult> _mockPurchase(String productId) async {
    await Future.delayed(const Duration(seconds: 2));
    _mixpanel.trackEvent('Mock Purchase Completed',
        properties: {'product_id': productId});
    return PurchaseResult.success;
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _completePurchase(purchase);
          if (onPurchaseUpdate != null) {
            onPurchaseUpdate!(PurchaseResult.success);
          } else {
            onBackgroundPurchaseCompleted?.call(purchase.productID);
          }
          _mixpanel.trackEvent('IAP Purchase Success', properties: {
            'product_id': purchase.productID,
            'status': purchase.status.name,
          });
          break;
        case PurchaseStatus.error:
          _completePurchase(purchase);
          onPurchaseUpdate?.call(PurchaseResult.error,
              error: purchase.error?.message ?? 'Unknown error');
          _mixpanel.trackEvent('IAP Purchase Error', properties: {
            'product_id': purchase.productID,
            'error': purchase.error?.message,
          });
          break;
        case PurchaseStatus.canceled:
          _completePurchase(purchase);
          onPurchaseUpdate?.call(PurchaseResult.cancelled);
          break;
        case PurchaseStatus.pending:
          onPurchaseUpdate?.call(PurchaseResult.pending);
          break;
      }
    }
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchase);
    }
  }

  /// Restore previous purchases (for "Restore Purchases" button).
  Future<void> restorePurchases() async {
    if (!isRealPurchasesPlatform || !_storeAvailable) return;
    await InAppPurchase.instance.restorePurchases();
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}
