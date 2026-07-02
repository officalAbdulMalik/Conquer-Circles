import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_model.dart';
import 'notification_service.dart';

class BadgeService {
  final _client = Supabase.instance.client;

  static const _catalogCacheKey = 'badge_catalog_cache_v1';
  static String _claimedCacheKey(String userId) =>
      'badge_claimed_cache_v1_$userId';

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

  /// Returns EVERY badge from the `badges` table, merged with the current
  /// user's claimed badges (from the `profiles.badges` jsonb column and the
  /// `user_badges` table). Badges the user has not claimed have
  /// `unlockedAt == null`, so the UI can render them with a lock icon.
  ///
  /// The result is cached locally: the first call loads from Supabase and
  /// writes the cache; later calls are served from the local cache without
  /// hitting the network. Pass [forceRefresh] to re-fetch from Supabase.
  Future<List<BadgeModel>> getAllBadges({bool forceRefresh = false}) async {
    final user = _client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _readFromCache(prefs, user?.id);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    try {
      final List<dynamic> catalog = await _client
          .from('badges')
          .select('id, number, name, description, category, icon')
          .order('number', ascending: true);

      // Claimed badge id -> unlocked_at timestamp.
      final claimed = <String, String>{};

      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('badges')
            .eq('id', user.id)
            .maybeSingle();
        final profileBadges = profile?['badges'];
        if (profileBadges is List) {
          for (final id in profileBadges.whereType<String>()) {
            claimed[id] = DateTime.now().toIso8601String();
          }
        }

        final List<dynamic> userBadges = await _client
            .from('user_badges')
            .select('badge_id, unlocked_at')
            .eq('user_id', user.id);
        for (final row in userBadges) {
          final badgeId = row['badge_id'] as String?;
          if (badgeId == null) continue;
          claimed[badgeId] =
              row['unlocked_at'] as String? ??
              claimed[badgeId] ??
              DateTime.now().toIso8601String();
        }
      }

      final catalogMaps = catalog
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .toList();

      // Persist locally so the next load doesn't hit the network.
      await prefs.setString(_catalogCacheKey, jsonEncode(catalogMaps));
      if (user != null) {
        await prefs.setString(_claimedCacheKey(user.id), jsonEncode(claimed));
      }

      return _merge(catalogMaps, claimed);
    } catch (e) {
      print('[BadgeService.getAllBadges] $e');
      // Network failed: fall back to whatever cache we have.
      return _readFromCache(prefs, user?.id) ?? [];
    }
  }

  /// Builds the badge list from the local cache. Returns null if no cache.
  List<BadgeModel>? _readFromCache(SharedPreferences prefs, String? userId) {
    final rawCatalog = prefs.getString(_catalogCacheKey);
    if (rawCatalog == null) return null;

    try {
      final catalogMaps = (jsonDecode(rawCatalog) as List)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .toList();

      final claimed = <String, String>{};
      if (userId != null) {
        final rawClaimed = prefs.getString(_claimedCacheKey(userId));
        if (rawClaimed != null) {
          (jsonDecode(rawClaimed) as Map).forEach(
            (key, value) => claimed[key.toString()] = value.toString(),
          );
        }
      }

      return _merge(catalogMaps, claimed);
    } catch (e) {
      print('[BadgeService._readFromCache] $e');
      return null;
    }
  }

  List<BadgeModel> _merge(
    List<Map<String, dynamic>> catalogMaps,
    Map<String, String> claimed,
  ) {
    return catalogMaps.map((raw) {
      final json = Map<String, dynamic>.from(raw);
      final id = json['id'] as String? ?? 'unknown_badge';
      if (claimed.containsKey(id)) {
        json['unlocked_at'] = claimed[id];
      } else {
        json.remove('unlocked_at');
      }
      return BadgeModel.fromJson(json);
    }).toList();
  }

  /// Records a freshly claimed badge in the local cache so the UI stays in
  /// sync without a network round trip.
  Future<void> _addClaimToCache(String userId, String badgeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final claimed = <String, String>{};
      final raw = prefs.getString(_claimedCacheKey(userId));
      if (raw != null) {
        (jsonDecode(raw) as Map).forEach(
          (key, value) => claimed[key.toString()] = value.toString(),
        );
      }
      claimed[badgeId] = DateTime.now().toIso8601String();
      await prefs.setString(_claimedCacheKey(userId), jsonEncode(claimed));
    } catch (e) {
      print('[BadgeService._addClaimToCache] $e');
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

      // A DB trigger syncs badge_id into profiles.badges (jsonb). Update it
      // client-side too so the UI reflects the claim immediately.
      await _addBadgeToProfile(user.id, badgeId);
      await _addClaimToCache(user.id, badgeId);

      // Notify the user
      final title = BadgeModel.getTitle(badgeId);
      final isRare =
          badgeId.contains('legend') ||
          badgeId.contains('emperor') ||
          badgeId.contains('king');
      await NotificationService.notifyBadgeEarned(
        badgeName: title,
        isRare: isRare,
      );

      return true;
    } catch (e) {
      print('[BadgeService.unlockBadge] $e');
      return false;
    }
  }

  /// Appends [badgeId] to the profiles.badges jsonb column if not present.
  Future<void> _addBadgeToProfile(String userId, String badgeId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('badges')
          .eq('id', userId)
          .maybeSingle();

      final current = <String>[
        if (profile?['badges'] is List)
          ...(profile!['badges'] as List).whereType<String>(),
      ];
      if (current.contains(badgeId)) return;

      await _client
          .from('profiles')
          .update({
            'badges': [...current, badgeId],
          })
          .eq('id', userId);
    } catch (e) {
      print('[BadgeService._addBadgeToProfile] $e');
    }
  }

  /// Returns total number of territory captures by the user.
  Future<int> getCapturedTerritoriesCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final res = await _client
          .from('territory_attack_log')
          .select('id')
          .eq('attacker_id', user.id)
          .eq('captured', true);

      return res.length;
    } catch (e) {
      print('[BadgeService.getCapturedTerritoriesCount] $e');
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
    final totalCaptured = await getCapturedTerritoriesCount();
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
