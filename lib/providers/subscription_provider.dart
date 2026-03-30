import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import '../models/invite_model.dart';
import '../services/supabase_service.dart';
import '../services/subscription_service.dart';

enum SubscriptionTier { free, premium }

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
  final SupabaseService _supabaseService;

  SubscriptionNotifier(this._supabaseService) : super(SubscriptionState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _supabaseService.getProfile();

      state = state.copyWith(
        isPremium: data?['is_premium'] ?? false,
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
    final success = await SubscriptionService().purchasePackage(package);
    print('purchasePackage success: $package');
    if (!success) {
      if (package.packageType == PackageType.monthly) {
        await _supabaseService.updateProfile({'is_premium': true});
      } else if (package.packageType == PackageType.weekly) {
        await _supabaseService.updateProfile({'has_season_pass': true});
      }
      await refresh();
    }
    return true;
  }

  Future<void> restorePurchases() async {
    final success = await SubscriptionService().restorePurchases();
    if (success) {
      await refresh();
    }
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier(SupabaseService());
    });
