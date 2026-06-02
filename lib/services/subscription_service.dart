import 'dart:developer' as developer;

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // RevenueCat is currently disabled.
  //
  // /// Fetches the current offerings available for the user.
  // Future<Offerings?> getOfferings() async {
  //   try {
  //     Offerings offerings = await Purchases.getOfferings();
  //     return offerings;
  //   } catch (e) {
  //     developer.log('Error fetching offerings: $e');
  //     return null;
  //   }
  // }
  //
  // /// Purchases a package and returns true if successful.
  // Future<bool> purchasePackage(Package package) async {
  //   try {
  //     // Newer API uses purchase with PurchaseParams
  //     final result = await Purchases.purchasePackage(package);
  //     return _isUserPremium(result.customerInfo);
  //   } catch (e) {
  //     if (e is PlatformException &&
  //         e.code == PurchasesErrorCode.purchaseCancelledError.index.toString()) {
  //       developer.log('Purchase cancelled by user');
  //     } else {
  //       developer.log('Error purchasing package: $e');
  //     }
  //     return false;
  //   }
  // }

  Future<Object?> getOfferings() async {
    developer.log('RevenueCat offerings requested while disabled.');
    return null;
  }

  Future<bool> purchasePackage(Object package) async {
    developer.log('RevenueCat purchase requested while disabled: $package');
    return false;
  }

  /// Restores previous purchases.
  Future<bool> restorePurchases() async {
    developer.log('RevenueCat restore requested while disabled.');
    return false;
  }

  /// Checks if the user has an active premium entitlement.
  Future<bool> checkPremiumStatus() async {
    developer.log('RevenueCat premium status requested while disabled.');
    return false;
  }

  // bool _isUserPremium(CustomerInfo customerInfo) {
  //   // Replace 'premium' with your actual entitlement ID from RevenueCat dashboard
  //   return customerInfo.entitlements.active.containsKey('premium') ||
  //          customerInfo.entitlements.active.containsKey('season_pass');
  // }

  /// Helper to get specific tier statuses
  Future<Map<String, bool>> getTierStatuses() async {
    return {'isPremium': false, 'hasSeasonPass': false};
  }
}
