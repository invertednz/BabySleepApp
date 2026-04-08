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

  /// Whether we're on a native platform that supports IAP (iOS or Android).
  bool get _isNativePlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Whether real IAP is available: native platform AND products actually loaded
  /// from the store. When products fail to load (e.g. not configured in App Store
  /// Connect), this returns false so the UI treats it like a mock/web purchase.
  bool get isRealPurchasesPlatform {
    return _isNativePlatform && _products.isNotEmpty;
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

    if (!_isNativePlatform) {
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

  /// Whether a product ID is an auto-renewing subscription (vs one-time purchase).
  bool _isSubscription(String productId) {
    return productId == ProductIds.monthly || productId == ProductIds.yearly;
  }

  /// Initiate a purchase. On web this runs the mock flow.
  /// On native platforms, products must be loaded from the store.
  Future<PurchaseResult> buyProduct(String productId) async {
    // Web: mock purchase (no real IAP on web)
    if (kIsWeb) {
      return _mockPurchase(productId);
    }

    // Native: require real store products
    if (!isRealPurchasesPlatform) {
      _mixpanel.trackEvent('IAP Store Not Available',
          properties: {'product_id': productId});
      return PurchaseResult.error;
    }

    final product = _products[productId];
    if (product == null) {
      _mixpanel.trackEvent('IAP Product Not Found In Store',
          properties: {'product_id': productId});
      return PurchaseResult.error;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    bool started;

    if (_isSubscription(productId)) {
      // Auto-renewing subscriptions use the subscription purchase flow
      started = await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      // Note: Flutter's in_app_purchase package uses buyNonConsumable for
      // auto-renewing subscriptions on both iOS and Android. The store
      // determines the billing type based on the product configuration
      // in App Store Connect / Google Play Console, not the client method.
    } else {
      // One-time purchases (payforward, gift)
      started = await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }

    if (!started) {
      return PurchaseResult.error;
    }
    // The actual result comes through the purchase stream.
    return PurchaseResult.pending;
  }

  /// Mock purchase for the web platform only.
  Future<PurchaseResult> _mockPurchase(String productId) async {
    assert(kIsWeb, 'Mock purchases should only run on web');
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
    if (!_isNativePlatform || !_storeAvailable) return;
    await InAppPurchase.instance.restorePurchases();
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}
