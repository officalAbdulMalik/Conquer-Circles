import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/invite_model.dart';
import '../services/supabase_service.dart';
import '../services/subscription_service.dart';

enum SubscriptionTier { free, premium }

/// Subscription packages for the upgrade paywall (excludes energy consumables).
final subscriptionPackagesProvider =
    FutureProvider.autoDispose<List<Package>>((ref) async {
  return SubscriptionService().getSubscriptionPackages();
});

/// Consumable energy packs for the buy-energy Marketplace (excludes subs).
final energyPackagesProvider =
    FutureProvider.autoDispose<List<Package>>((ref) async {
  return SubscriptionService().getEnergyPackages();
});

/// Debug-only summary of the RevenueCat offerings/packages, used to diagnose an
/// empty marketplace.
final offeringsDebugProvider = FutureProvider.autoDispose<String>((ref) async {
  return SubscriptionService().offeringsDebugSummary();
});

class SubscriptionState {
  final bool isPremium;
  final bool hasSeasonPass;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  SubscriptionState({
    this.isPremium = false,
    this.hasSeasonPass = false,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  SubscriptionTier get tier =>
      isPremium ? SubscriptionTier.premium : SubscriptionTier.free;

  int get maxCircles => tier == SubscriptionTier.premium ? 5 : 1;

  bool get hasUnlimitedInvites => tier == SubscriptionTier.premium;

  int get maxFreeInvites => 3;

  int get energyCap => tier == SubscriptionTier.premium ? 600 : 400;

  SubscriptionState copyWith({
    bool? isPremium,
    bool? hasSeasonPass,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      hasSeasonPass: hasSeasonPass ?? this.hasSeasonPass,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptions = SubscriptionService();
  final SupabaseService _supabaseService;
  StreamSubscription<bool>? _proSub;

  SubscriptionNotifier(this._supabaseService) : super(SubscriptionState()) {
    // React live to purchases, cancellations, and expiries.
    _proSub = _subscriptions.proStream.listen((pro) {
      state = state.copyWith(isPremium: pro);
    });
    refresh();
  }

  @override
  void dispose() {
    _proSub?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _supabaseService.getProfile();
      // RevenueCat is the source of truth; re-check and sync the flag, then
      // OR it with the persisted profile value.
      final rcPro = await _subscriptions.refreshProStatus();

      state = state.copyWith(
        isPremium: (data?['is_premium'] ?? false) || rcPro,
        hasSeasonPass: data?['has_season_pass'] ?? false,
        profile: data != null ? UserProfile.fromJson(data) : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true, error: null);
    // The pro-stream listener flips isPremium; this just manages the spinner.
    final success = await _subscriptions.purchasePackage(package);
    state = state.copyWith(isLoading: false);
    return success;
  }

  Future<bool> restorePurchases() async {
    return _subscriptions.restorePurchases();
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier(SupabaseService());
    });
