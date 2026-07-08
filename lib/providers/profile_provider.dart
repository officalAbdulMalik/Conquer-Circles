import 'package:flutter/foundation.dart';
import 'package:riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../services/game_service.dart';

import '../models/profile_data_model.dart';
import 'settings_provider.dart';

class ProfileState {
  final ProfileDataModel? profileData;
  final Map<String, dynamic>? trustStatus;
  final bool isLoading;
  final String? error;
  final String currentWeightGoal;
  final int currentStepGoal;
  final bool isGoalsLoading;
  final bool isDeletingAccount;

  ProfileState({
    this.profileData,
    this.trustStatus,
    this.isLoading = false,
    this.error,
    this.currentWeightGoal = 'Lose Weight',
    this.currentStepGoal = 5000,
    this.isGoalsLoading = false,
    this.isDeletingAccount = false,
  });

  ProfileState copyWith({
    ProfileDataModel? profileData,
    Map<String, dynamic>? trustStatus,
    bool? isLoading,
    String? error,
    String? currentWeightGoal,
    int? currentStepGoal,
    bool? isGoalsLoading,
    bool? isDeletingAccount,
  }) {
    return ProfileState(
      profileData: profileData ?? this.profileData,
      trustStatus: trustStatus ?? this.trustStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentWeightGoal: currentWeightGoal ?? this.currentWeightGoal,
      currentStepGoal: currentStepGoal ?? this.currentStepGoal,
      isGoalsLoading: isGoalsLoading ?? this.isGoalsLoading,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
    );
  }
}



class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;
  final SupabaseService supabaseService;
  final GameService gameService;

  ProfileNotifier(this.ref, this.supabaseService, this.gameService)
    : super(ProfileState()) {
    refreshProfile();
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profileData = await supabaseService.getProfileData();
      final trustStatus = await gameService.getTrustStatus();

      // Hydrate settingsProvider with settings from profile
      ref.read(settingsProvider.notifier).initializeFromProfile(profileData.profile);

      state = state.copyWith(
        profileData: profileData,
        trustStatus: trustStatus,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    try {
      await supabaseService.updateNotificationSettings(enabled);

      print('$enabled is updated');
      if (state.profileData != null) {
        state = state.copyWith(
          profileData: state.profileData!.copyWith(
            profile: state.profileData!.profile.copyWith(
              notificationsEnabled: enabled,
            ),
          ),
        );
      }
    } catch (e) {
      print('[ProfileNotifier.toggleNotifications] $e');
    }
  }

  // logout method to clear local data and sign out from Supabase
  Future<void> logout() async {
    try {
      debugPrint('🚪 [Session] Starting logout...');
      
      // Clear local state immediately
      state = ProfileState();
      debugPrint('✅ [Session] Cleared profile state');
      
      // Sign out from Supabase (this triggers AuthStateChange)
      await supabaseService.signOut();
      debugPrint('✅ [Session] Signed out from Supabase');
      
    } catch (e) {
      print('[ProfileNotifier.logout] Error: $e');
      // Even if error, clear local state to ensure clean slate
      state = ProfileState();
    }
  }

  /// Permanently deletes the current account, then clears the local session so
  /// the app returns to the auth gate.
  ///
  /// The server removes the auth user and all cascaded data immediately, so the
  /// account can no longer be signed into. Throws on failure so the UI can
  /// surface an error without logging the user out.
  Future<void> deleteAccount() async {
    state = state.copyWith(isDeletingAccount: true, error: null);
    try {
      await supabaseService.requestAccountDeletion();
    } catch (e) {
      debugPrint('[ProfileNotifier.deleteAccount] $e');
      state = state.copyWith(isDeletingAccount: false, error: e.toString());
      rethrow;
    }

    // Account is gone server-side; drop the local session (local scope, since
    // the server token is now invalid) to route back to the auth gate.
    state = ProfileState();
    try {
      await supabaseService.signOutLocal();
    } catch (e) {
      debugPrint('[ProfileNotifier.deleteAccount] local sign-out: $e');
    }
  }

  Future<void> loadCurrentGoals() async {
    state = state.copyWith(isGoalsLoading: true);
    try {
      final profile = await supabaseService.getProfile();
      state = state.copyWith(
        currentWeightGoal: (profile?['weight_goal'] as String?) ?? 'Lose Weight',
        currentStepGoal: (profile?['step_goal'] as int?) ?? (profile?['daily_steps_goal'] as int?) ?? 5000,
        isGoalsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isGoalsLoading: false);
    }
  }

  Future<void> updateGoals({
    required String weightGoal,
    required int dailyStepsGoal,
  }) async {
    state = state.copyWith(isGoalsLoading: true);
    try {
      await supabaseService.updateGoals(
        weightGoal: weightGoal,
        dailyStepsGoal: dailyStepsGoal,
      );
      state = state.copyWith(
        currentWeightGoal: weightGoal,
        currentStepGoal: dailyStepsGoal,
        isGoalsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isGoalsLoading: false);
      rethrow;
    }
  }

  Future<void> checkForBadges(
    String eventType, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      final result = await supabaseService.checkAndAwardBadges(
        eventType,
        payload,
      );
      if (result['success'] == true && (result['awarded'] as List).isNotEmpty) {
        // If badges were awarded, refresh profile to update UI
        await refreshProfile();
      }
    } catch (e) {
      print('[ProfileNotifier.checkForBadges] $e');
    }
  }
}



final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref, SupabaseService(), GameService());
});

final userProfileProvider = FutureProvider<ProfileDataModel?>((ref) async {
  return SupabaseService().getProfileData();
});

final userTrustStatusProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  return GameService().getTrustStatus();
});
