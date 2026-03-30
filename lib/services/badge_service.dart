import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_model.dart';
import 'notification_service.dart';

class BadgeService {
  final _client = Supabase.instance.client;

  /// Returns all badges unlocked by the current user.
  Future<List<BadgeModel>> getUnlockedBadges() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final List<dynamic> res = await _client
          .from('user_badges')
          .select()
          .eq('user_id', user.id);

      return res
          .map((json) => BadgeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[BadgeService.getUnlockedBadges] $e');
      return [];
    }
  }

  /// Unlocks a badge for the current user. Returns true if newly unlocked.
  Future<bool> unlockBadge(String badgeId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // Check if already unlocked to avoid unnecessary inserts/duplicates
      final existing = await _client
          .from('user_badges')
          .select('id')
          .eq('user_id', user.id)
          .eq('badge_id', badgeId)
          .maybeSingle();

      if (existing != null) return false;

      await _client.from('user_badges').insert({
        'user_id': user.id,
        'badge_id': badgeId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      // Notify the user
      final title = BadgeModel.getTitle(badgeId);
      final isRare = badgeId.contains('legend') || badgeId.contains('emperor') || badgeId.contains('king');
      await NotificationService.notifyBadgeEarned(badgeName: title, isRare: isRare);

      return true;
    } catch (e) {
      print('[BadgeService.unlockBadge] $e');
      return false;
    }
  }

  /// Returns total number of tiles captured by the user.
  Future<int> getCapturedTilesCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final res = await _client
          .from('hex_tiles')
          .select('id')
          .eq('owner_id', user.id);

      return res.length;
    } catch (e) {
      print('[BadgeService.getCapturedTilesCount] $e');
      return 0;
    }
  }

  /// Checks and unlocks step-based badges.
  Future<void> checkStepAchievements(int currentSteps) async {
    if (currentSteps >= 5000) {
      await unlockBadge('step_rookie');
    }
    // More complex step badges (like streaks) would require historical data query here
  }

  /// Checks and unlocks territory-based badges.
  Future<void> checkTerritoryAchievements() async {
    final totalCaptured = await getCapturedTilesCount();
    if (totalCaptured >= 10) await unlockBadge('territory_pioneer');
    if (totalCaptured >= 50) await unlockBadge('territory_builder');
    if (totalCaptured >= 100) await unlockBadge('expansion_master');
  }

  /// Checks and unlocks raid-based badges.
  Future<void> checkRaidAchievements(int wins) async {
    if (wins >= 1) await unlockBadge('raid_initiator');
    if (wins >= 10) await unlockBadge('raid_champion');
    if (wins >= 25) await unlockBadge('raid_destroyer');
  }
}
