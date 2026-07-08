import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'supabase_service.dart';

/// Single entry point for everything subscription-related. RevenueCat is the
/// source of truth for entitlements; this service logs the user in/out, runs
/// purchases/restores, exposes the current "pro" status, and mirrors it into
/// the Supabase `profiles.is_premium` flag whenever it changes (purchase,
/// cancellation, expiry, restore).
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// A user has "pro" access if any RevenueCat entitlement is active. Set a
  /// specific id here if you want to gate on one entitlement only.
  static const String? proEntitlementId = null;

  final SupabaseService _supabase = SupabaseService();
  final StreamController<bool> _proController = StreamController<bool>.broadcast();

  bool _hasPro = false;
  bool _listenerAttached = false;

  /// Live pro-access status. Emits on every RevenueCat customer-info change.
  Stream<bool> get proStream => _proController.stream;
  bool get hasPro => _hasPro;

  /// Attach the RevenueCat listener. Call once after `Purchases.configure`.
  void init() {
    if (_listenerAttached) return;
    _listenerAttached = true;
    Purchases.addCustomerInfoUpdateListener(_handleCustomerInfo);
  }

  /// Log the user into RevenueCat so entitlements follow their account.
  /// Call after Supabase sign-in / on session restore.
  Future<void> login(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      await _handleCustomerInfo(result.customerInfo);
    } catch (e) {
      developer.log('RevenueCat login failed: $e');
    }
  }

  /// Log the user out of RevenueCat. Call on Supabase sign-out.
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } on PlatformException catch (e) {
      // Logging out an anonymous user throws; that's harmless here.
      developer.log('RevenueCat logout: ${e.message}');
    } catch (e) {
      developer.log('RevenueCat logout failed: $e');
    }
    _updatePro(false, sync: false);
  }

  /// Fetches the current offerings (packages to show on the paywall).
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      developer.log('Error fetching offerings: $e');
      return null;
    }
  }

  /// Every unique package across all offerings.
  Future<List<Package>> _allPackages() async {
    final offerings = await Purchases.getOfferings();
    final seen = <String>{};
    final result = <Package>[];
    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        if (seen.add(package.storeProduct.identifier)) result.add(package);
      }
    }
    return result;
  }

  /// Subscription packages only (auto-renewing / non-renewing) — for the
  /// upgrade paywall. Consumables (energy) are excluded.
  Future<List<Package>> getSubscriptionPackages() async {
    try {
      final packages = await _allPackages();
      return packages
          .where((p) =>
              p.storeProduct.productCategory == ProductCategory.subscription)
          .toList();
    } catch (e) {
      developer.log('Error fetching subscription packages: $e');
      return [];
    }
  }

  /// Consumable (non-subscription) packages across all offerings — the energy
  /// packs shown on the buy-energy Marketplace. Lenient: anything not clearly a
  /// subscription counts as energy.
  Future<List<Package>> getEnergyPackages() async {
    try {
      final packages = await _allPackages();
      return packages
          .where((p) =>
              p.storeProduct.productCategory != ProductCategory.subscription)
          .toList();
    } catch (e) {
      developer.log('Error fetching energy packages: $e');
      return [];
    }
  }

  /// Human-readable dump of what RevenueCat returns, for debugging an empty
  /// paywall/marketplace (which offerings exist and how many packages each has).
  Future<String> offeringsDebugSummary() async {
    try {
      final offerings = await Purchases.getOfferings();
      final buffer = StringBuffer()
        ..writeln('current: ${offerings.current?.identifier ?? "none"}')
        ..writeln('offerings: ${offerings.all.length}');
      offerings.all.forEach((id, offering) {
        final ids = offering.availablePackages
            .map((p) =>
                '${p.identifier}(${p.storeProduct.identifier} · ${p.storeProduct.productCategory?.name ?? "?"})')
            .join(', ');
        buffer.writeln('• $id → ${offering.availablePackages.length} pkg'
            '${ids.isEmpty ? '' : ': $ids'}');
      });
      return buffer.toString().trim();
    } catch (e) {
      return 'getOfferings error: $e';
    }
  }

  /// Buys a consumable energy package. Returns the store transaction id on
  /// success (used as the idempotency key when granting energy), or null if the
  /// purchase was cancelled or failed.
  Future<String?> purchaseEnergy(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final productId = package.storeProduct.identifier;
      String? txId;
      try {
        final txns = result.customerInfo.nonSubscriptionTransactions
            .where((t) => t.productIdentifier == productId)
            .toList()
          ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        if (txns.isNotEmpty) txId = txns.first.transactionIdentifier;
      } catch (_) {
        // ignore parsing issues; fall back to a synthetic key below
      }
      // The transaction id, or a synthetic key so the grant still runs.
      return txId ?? '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        developer.log('Energy purchase failed: ${e.message}');
      }
      return null;
    } catch (e) {
      developer.log('Energy purchase failed: $e');
      return null;
    }
  }

  /// Purchases a package. Returns true if the user now has pro access.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      await _handleCustomerInfo(result.customerInfo);
      return _hasPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        developer.log('Purchase cancelled by user');
      } else {
        developer.log('Error purchasing package: ${e.message}');
      }
      return false;
    } catch (e) {
      developer.log('Error purchasing package: $e');
      return false;
    }
  }

  /// Restores previous purchases. Returns true if pro is now active.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      await _handleCustomerInfo(info);
      return _hasPro;
    } catch (e) {
      developer.log('Error restoring purchases: $e');
      return false;
    }
  }

  /// Re-checks entitlements from RevenueCat and syncs the flag. Returns pro.
  Future<bool> refreshProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      await _handleCustomerInfo(info);
    } catch (e) {
      developer.log('Error refreshing pro status: $e');
    }
    return _hasPro;
  }

  // ── internals ────────────────────────────────────────────────────────────

  Future<void> _handleCustomerInfo(CustomerInfo info) async {
    final active = info.entitlements.active;
    final pro = proEntitlementId != null
        ? active.containsKey(proEntitlementId)
        : active.isNotEmpty;
    await _updatePro(pro, sync: true);
  }

  Future<void> _updatePro(bool pro, {required bool sync}) async {
    final changed = pro != _hasPro;
    _hasPro = pro;
    if (changed && !_proController.isClosed) {
      _proController.add(pro);
    }
    if (sync) {
      // Mirror into Supabase so the rest of the app (and other devices) can
      // read a simple boolean without talking to RevenueCat.
      await _supabase.setPremium(pro);
    }
  }
}
