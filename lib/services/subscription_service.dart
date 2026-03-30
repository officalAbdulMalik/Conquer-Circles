import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Fetches the current offerings available for the user.
  Future<Offerings?> getOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      developer.log('Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchases a package and returns true if successful.
  Future<bool> purchasePackage(Package package) async {
    try {
      // Newer API uses purchase with PurchaseParams
      final result = await Purchases.purchasePackage(package);
      return _isUserPremium(result.customerInfo);
    } catch (e) {
      if (e is PlatformException && e.code == PurchasesErrorCode.purchaseCancelledError.index.toString()) {
        developer.log('Purchase cancelled by user');
      } else {
        developer.log('Error purchasing package: $e');
      }
      return false;
    }
  }

  /// Restores previous purchases.
  Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return _isUserPremium(customerInfo);
    } catch (e) {
      developer.log('Error restoring purchases: $e');
      return false;
    }
  }

  /// Checks if the user has an active premium entitlement.
  Future<bool> checkPremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return _isUserPremium(customerInfo);
    } catch (e) {
      developer.log('Error checking premium status: $e');
      return false;
    }
  }

  bool _isUserPremium(CustomerInfo customerInfo) {
    // Replace 'premium' with your actual entitlement ID from RevenueCat dashboard
    return customerInfo.entitlements.active.containsKey('premium') || 
           customerInfo.entitlements.active.containsKey('season_pass');
  }

  /// Helper to get specific tier statuses
  Future<Map<String, bool>> getTierStatuses() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return {
        'isPremium': customerInfo.entitlements.active.containsKey('premium'),
        'hasSeasonPass': customerInfo.entitlements.active.containsKey('season_pass'),
      };
    } catch (e) {
      return {'isPremium': false, 'hasSeasonPass': false};
    }
  }
}
