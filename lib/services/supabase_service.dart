import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invite_model.dart';
import '../models/notification_model.dart';
import '../models/profile_data_model.dart';
import '../models/walk_models.dart';

/// Central service for all Supabase interactions.
/// Every method is safe to call from any provider or screen.
class SupabaseService {
  final _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => _client.auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.conquercircles://login-callback',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.conquercircles://login-callback',
    );
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Returns the current user's profile row, or null if not found.
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      _log('getProfile', e);
      return null;
    }
  }

  /// Creates a profile row if one does not yet exist.
  /// Call this immediately after sign-up and on app launch.
  Future<void> ensureProfileExists() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _client.from('profiles').insert({
          'id': user.id,
          'username':
              user.email?.split('@').first ?? 'User_${user.id.substring(0, 5)}',
        });
      }
    } catch (e) {
      _log('ensureProfileExists', e);
      rethrow;
    }
  }

  /// Save or update the FCM token for push notifications.
  Future<void> saveFcmToken(String token) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      _log('saveFcmToken', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Daily Steps
  // ---------------------------------------------------------------------------

  /// Returns today's step count from the database.
  Future<int> getStepsForDate(String date) async {
    final user = currentUser;
    if (user == null) return 0;
    try {
      final List<dynamic> res = await _client
          .from('daily_steps')
          .select('steps')
          .eq('user_id', user.id)
          .eq('date', date)
          .order('updated_at', ascending: false)
          .limit(1);
      return res.isEmpty ? 0 : res.first['steps'] as int;
    } catch (e) {
      _log('getStepsForDate', e);
      return 0;
    }
  }

  /// Returns step counts for the last 7 days keyed by midnight DateTime.
  Future<Map<DateTime, int>> getWeeklyStepsFromSupabase() async {
    final user = currentUser;
    if (user == null) return {};
    try {
      final now = DateTime.now();
      final sevenDaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));

      final List<dynamic> res = await _client
          .from('daily_steps')
          .select('date, steps')
          .eq('user_id', user.id)
          .gte('date', sevenDaysAgo.toIso8601String().split('T').first)
          .order('date', ascending: true);

      return {
        for (final row in res)
          DateTime.parse(row['date'] as String): row['steps'] as int,
      };
    } catch (e) {
      _log('getWeeklyStepsFromSupabase', e);
      return {};
    }
  }

  /// Upserts today's step count and triggers attack_energy and XP conversion.
  /// Returns a map with { attack_energy, xp_gained, level_up, new_level }
  Future<Map<String, dynamic>> upsertSteps(int steps) async {
    final user = currentUser;
    if (user == null) return {};
    final date = DateTime.now().toIso8601String().split('T').first;
    try {
      // 1. Persist step count
      await _client.from('daily_steps').upsert({
        'user_id': user.id,
        'date': date,
        'steps': steps,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,date');

      // 2. Convert steps → attack_energy via RPC
      final energyResult = await convertStepsToEnergy(steps);

      // 3. Convert steps → XP via RPC (with level progression)
      final xpResult = await convertStepsToXP(steps);

      return {
        'success': true,
        'attack_energy': energyResult['attack_energy'] as int? ?? 0,
        'xp_gained': xpResult['xp_gained'] as int? ?? 0,
        'current_xp': xpResult['current_xp'] as int? ?? 0,
        'current_level': xpResult['current_level'] as int? ?? 1,
        'xp_goal': xpResult['xp_goal'] as int? ?? 1000,
        'level_up': xpResult['level_up'] as bool? ?? false,
      };
    } catch (e) {
      _log('upsertSteps', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // Attack Energy
  // ---------------------------------------------------------------------------

  /// Calls the Supabase RPC that derives attack_energy from today's steps.
  /// 100 steps = 1 attack energy. Daily cap: 400 (free) / 600 (premium).
  /// Returns the full RPC result map.
  Future<Map<String, dynamic>> convertStepsToEnergy(int stepsToday) async {
    final user = currentUser;
    if (user == null) return {};
    try {
      final response = await _client.rpc(
        'convert_steps_to_energy',
        params: {'p_user_id': user.id, 'p_steps_today': stepsToday},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('convertStepsToEnergy', e);
      return {};
    }
  }

  /// Calls the Supabase RPC that converts steps to XP with level progression.
  /// 1 step = 0.1 XP. Daily goal bonus: +50 XP if 10000+ steps.
  /// Returns { xp_gained, current_xp, current_level, xp_goal, level_up }
  Future<Map<String, dynamic>> convertStepsToXP(int stepsToday) async {
    final user = currentUser;
    if (user == null) return {};
    try {
      final response = await _client.rpc(
        'convert_steps_to_xp',
        params: {'p_user_id': user.id, 'p_steps_today': stepsToday},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('convertStepsToXP', e);
      return {};
    }
  }

  /// Returns the current attack_energy for the signed-in user.
  Future<int> getAttackEnergy() async {
    final user = currentUser;
    if (user == null) return 0;
    try {
      final res = await _client
          .from('profiles')
          .select('attack_energy')
          .eq('id', user.id)
          .single();
      return res['attack_energy'] as int? ?? 0;
    } catch (e) {
      _log('getAttackEnergy', e);
      return 0;
    }
  }

  Future<ProfileDataModel> getProfileData() async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    final currentSession = _client.auth.currentSession;
    final token = currentSession?.accessToken;

    try {
      final response = await _client.functions.invoke(
        'get-profile-data',
        body: {"user_id": user.id},
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      if (response.status != 200 && response.status != 201) {
        throw Exception(
          'Function returned status ${response.status}: ${response.data}',
        );
      }

      return ProfileDataModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e) {
      _log('getProfileData', e);
      rethrow;
    }
  }

  Future<void> updateNotificationSettings(bool enabled) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _client
          .from('profiles')
          .update({'notifications_enabled': enabled})
          .eq('id', user.id);
    } catch (e) {
      _log('updateNotificationSettings', e);
      rethrow;
    }
  }

  /// Fetches unified dashboard data from the Edge Function with retry logic.
  Future<Map<String, dynamic>> getStepsDashboardData() async {
    var session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No active session');
    }

    try {
      return await _invokeFunction();
    } on FunctionException catch (e) {
      if (e.status == 401) {
        _log('getStepsDashboardData - Got 401, attempting token refresh', null);
      }

      _log('getStepsDashboardData - FunctionException', e);
      rethrow;
    } catch (e) {
      _log('getStepsDashboardData', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkAndAwardBadges(
    String eventType, [
    Map<String, dynamic>? payload,
  ]) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'not signed in'};

    final currentSession = _client.auth.currentSession;
    final token = currentSession?.accessToken;

    try {
      final response = await _client.functions.invoke(
        'add-badge',
        body: {
          "user_id": user.id,
          "event_type": eventType,
          if (payload != null) "payload": payload,
        },
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      _log(
        'checkAndAwardBadges response: ${response.data}',
        'checkAndAwardBadges',
      );

      if (response.status != 200 && response.status != 201) {
        throw Exception(
          'Function returned status ${response.status}: ${response.data}',
        );
      }

      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      _log('checkAndAwardBadges', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _invokeFunction() async {
    // Always read the freshest session token at call time
    final currentSession = _client.auth.currentSession;
    final token = currentSession?.accessToken;

    final response = await _client.functions.invoke(
      'get-steps-dashboard',
      body: {"user_id": currentUser?.id},
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );

    _log(
      'getStepsDashboardData response: ${response.data}',
      'getStepsDashboardData',
    );

    if (response.status != 200 && response.status != 201) {
      throw Exception(
        'Function returned status ${response.status}: ${response.data}',
      );
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Safe sign out that doesn't throw (prevents breaking auth listeners)
  Future<void> _safeSiginOut() async {
    try {
      await _client.auth.signOut();
      _log('Safely signed out user', null);
    } catch (e) {
      _log('Error during safe sign out', e);
      // Don't rethrow - we already have an error to report
    }
  }

  /// Creates a new walking session row. Returns the session UUID.
  /// Automatically cancels any previously stuck active session first.
  /// Call this when the user presses "Start Walk".
  Future<String?> startWalkingSession() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      await ensureProfileExists();

      // RPC auto-cancels any existing active session then creates a new one
      final response = await _client.rpc(
        'start_walking_session',
        params: {'p_user_id': user.id},
      );

      final result = Map<String, dynamic>.from(response as Map);
      final success = result['success'] as bool? ?? false;
      if (!success) return null;

      return result['session_id'] as String;
    } catch (e) {
      _log('startWalkingSession', e);
      rethrow;
    }
  }

  /// Inserts a single GPS point. Call every ~5 seconds while walking.
  Future<void> recordLocationPoint(LocationPoint point) async {
    try {
      await _client.from('location_points').insert(point.toJson());
    } catch (e) {
      _log('recordLocationPoint', e);
    }
  }

  /// Ends the session, merges the new convex hull into the existing territory,
  /// and sets a 12-hour protection window.
  /// Returns the RPC result map with keys: status, area_m2, merged, point_count.
  Future<Map<String, dynamic>> endWalkingSession(String sessionId) async {
    try {
      final response = await _client.rpc(
        'end_walking_session',
        params: {'p_session_id': sessionId},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('endWalkingSession', e);
      return {'error': 'Failed to end walk: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // Territory
  // ---------------------------------------------------------------------------

  /// Returns territories within [radius] metres of [lat]/[lng].
  /// Own territory is forced to blue. Strangers are excluded (friends only).
  Future<List<Territory>> getNearbyTerritories(
    double lat,
    double lng, {
    double radius = 5000,
  }) async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final List<dynamic> raw = await _client.rpc(
        'get_territories_nearby',
        params: {'p_lat': lat, 'p_lng': lng, 'p_radius_m': radius},
      );

      // Fetch accepted friend IDs
      final friendIds = await getAcceptedInviteUserIds();
      final friendSet = Set<String>.from(friendIds);

      // Filter to own + friends only
      final filtered = raw.where((t) {
        final tid = t['user_id']?.toString();
        return tid == null || tid == user.id || friendSet.contains(tid);
      }).toList();

      return filtered.map((t) {
        final territory = Territory.fromJson(t as Map<String, dynamic>);
        return t['user_id'] == user.id
            ? territory.copyWith(color: '#2196F3')
            : territory;
      }).toList();
    } catch (e) {
      _log('getNearbyTerritories', e);
      return [];
    }
  }

  /// Returns the signed-in user's own territory.
  Future<Territory?> getHomeTerritory() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final response = await _client.rpc(
        'get_home_territory',
        params: {'p_user_id': user.id},
      );
      if (response == null) return null;
      return Territory.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _log('getHomeTerritory', e);
      return null;
    }
  }

  /// Upserts only metadata fields (color, shield, energy).
  /// Never writes the geom column — that is owned by the SQL RPC.
  Future<void> upsertTerritoryMetadata(Territory territory) async {
    final user = currentUser;
    if (user == null) return;
    try {
      final profile = await getProfile();
      final username = profile?['username'] as String? ?? 'Conqueror';
      final json = territory.toJson()
        ..remove('geom')
        ..remove('polygon_points')
        ..['username'] = username
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('territories').upsert(json, onConflict: 'user_id');
    } catch (e) {
      _log('upsertTerritoryMetadata', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Territory Attack System
  // ---------------------------------------------------------------------------

  /// Attack or reinforce a territory. Call when the user walks at valid speed (2-15 km/h).
  ///
  /// - If territory is owned by attacker: reinforces (adds energy, costs 0-20 energy)
  /// - If territory is owned by friend: attacks (costs full energy, can capture or damage)
  /// - If neutral: claims (costs 0-20 energy)
  ///
  /// Possible [action] values in the returned map:
  ///   'reinforced'  — own territory reinforced with energy
  ///   'damaged'     — enemy territory energy reduced (not captured)
  ///   'captured'    — enemy territory taken (new owner)
  ///   'protected'   — territory in 12h protection window
  ///   'shielded'    — territory in 24h absence shield
  ///   'cooldown'    — attacker on 30-min cooldown for this territory
  ///   'no_energy'   — attacker has 0 attack energy
  ///   'error'       — validation failed (speed, friend, not_found, etc)
  Future<Map<String, dynamic>> attackOrClaimTerritory({
    required String territoryId,
    required double speedKmh,
    required double lat,
    required double lng,
  }) async {
    final user = currentUser;
    if (user == null) return {'action': 'error', 'message': 'not signed in'};
    try {
      final response = await _client.rpc(
        'attack_or_claim_territory',
        params: {
          'p_territory_id': territoryId,
          'p_user_id': user.id,
          'p_speed_kmh': speedKmh,
          'p_lat': lat,
          'p_lng': lng,
        },
      );
      final result = Map<String, dynamic>.from(response as Map);
      return result;
    } catch (e) {
      _log('attackOrClaimTerritory', e);
      return {'action': 'error', 'message': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // (DEPRECATED) Hex Tile Attack System - DO NOT USE
  // ---------------------------------------------------------------------------
  // The following methods are for the old hex tile system and are deprecated.
  // Use attackOrClaimTerritory() instead for the new territory system.

  /// (DEPRECATED) Main game action for hex tiles. DO NOT USE.
  /// Use attackOrClaimTerritory() instead.
  Future<Map<String, dynamic>> claimOrAttackTile({
    required String tileId,
    required double lat,
    required double lng,
  }) async {
    final user = currentUser;
    if (user == null) return {'action': 'error', 'message': 'not signed in'};
    try {
      final response = await _client.rpc(
        'claim_or_attack_tile',
        params: {
          'p_tile_id': tileId,
          'p_user_id': user.id,
          'p_lat': lat,
          'p_lng': lng,
        },
      );
      final result = Map<String, dynamic>.from(response as Map);

      return result;
    } catch (e) {
      _log('claimOrAttackTile', e);
      return {'action': 'error', 'message': e.toString()};
    }
  }

  /// Returns the current state of a single hex tile, or null if unclaimed.
  Future<Map<String, dynamic>?> getTileState(String tileId) async {
    try {
      return await _client
          .from('hex_tiles')
          .select(
            'tile_id, owner_id, tile_energy, protection_until, last_visited_at',
          )
          .eq('tile_id', tileId)
          .maybeSingle();
    } catch (e) {
      _log('getTileState', e);
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').update(updates).eq('id', user.id);
    } catch (e) {
      _log('updateProfile', e);
      rethrow;
    }
  }

  /// Returns true if the signed-in user still has an active cooldown on [tileId].
  Future<bool> hasCooldown(String tileId) async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final res = await _client
          .from('attack_cooldowns')
          .select('cooldown_until')
          .eq('attacker_id', user.id)
          .eq('tile_id', tileId)
          .maybeSingle();
      if (res == null) return false;
      return DateTime.parse(
        res['cooldown_until'] as String,
      ).isAfter(DateTime.now());
    } catch (e) {
      _log('hasCooldown', e);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Invite System
  // ---------------------------------------------------------------------------

  /// Searches ALL users by username — includes already-invited users.
  /// Used on the invite discovery screen where you want to see everyone.
  Future<List<UserProfile>> searchAllUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final user = currentUser;
    try {
      var builder = _client
          .from('profiles')
          .select()
          .ilike('username', '%$query%');

      // Exclude only the current user from results
      if (user != null) {
        builder = builder.neq('id', user.id);
      }

      final res = await builder.limit(20);
      return (res as List).map((u) => UserProfile.fromJson(u)).toList();
    } catch (e) {
      _log('searchAllUsers', e);
      return [];
    }
  }

  /// Searches users excluding anyone already in a pending/accepted invite
  /// relationship with the current user. Used on the "Send Invite" screen.
  Future<List<UserProfile>> searchUsers(String query) async {
    final user = currentUser;
    if (user == null || query.isEmpty) return [];
    try {
      // Exclude already-invited users
      final existing = await _client
          .from('invites')
          .select('inviter_id, invitee_id')
          .or('inviter_id.eq.${user.id},invitee_id.eq.${user.id}')
          .inFilter('status', ['pending', 'accepted']);

      final excluded = <String>{user.id};
      for (final row in existing as List) {
        excluded.add(row['inviter_id'] as String);
        excluded.add(row['invitee_id'] as String);
      }

      final res = await _client
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .filter('id', 'not.in', '(${excluded.join(',')})')
          .limit(10);

      return (res as List).map((u) => UserProfile.fromJson(u)).toList();
    } catch (e) {
      _log('searchUsers', e);
      return [];
    }
  }

  /// Sends a friend invite and an FCM notification to the invitee.
  Future<void> sendInvite(String inviteeId) async {
    final user = currentUser;
    if (user == null) return;
    if (user.id == inviteeId) throw Exception('Cannot invite yourself');
    try {
      await _client.from('invites').insert({
        'inviter_id': user.id,
        'invitee_id': inviteeId,
        'status': 'pending',
      });
      await sendNotification(
        inviteeId,
        'New territory invite!',
        'You have been invited to play Territory Walk.',
      );
    } catch (e) {
      _log('sendInvite', e);
      rethrow;
    }
  }

  Future<List<Invite>> getReceivedInvites() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await _client
          .from('invites')
          .select('*, inviter:profiles!inviter_id(username)')
          .eq('invitee_id', user.id)
          .order('created_at', ascending: false);
      return (res as List).map((i) => Invite.fromJson(i)).toList();
    } catch (e) {
      _log('getReceivedInvites', e);
      return [];
    }
  }

  Future<List<Invite>> getSentInvites() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await _client
          .from('invites')
          .select('*, invitee:profiles!invitee_id(username)')
          .eq('inviter_id', user.id)
          .order('created_at', ascending: false);
      return (res as List).map((i) => Invite.fromJson(i)).toList();
    } catch (e) {
      _log('getSentInvites', e);
      return [];
    }
  }

  /// Accepts or rejects an invite. Pass 'accepted' or 'rejected'.
  Future<void> updateInviteStatus(String inviteId, String status) async {
    try {
      await _client
          .from('invites')
          .update({'status': status})
          .eq('id', inviteId);
    } catch (e) {
      _log('updateInviteStatus', e);
      rethrow;
    }
  }

  /// Returns IDs of all users with accepted invites (friends).
  Future<List<String>> getAcceptedInviteUserIds() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await _client
          .from('invites')
          .select('inviter_id, invitee_id')
          .eq('status', 'accepted')
          .or('inviter_id.eq.${user.id},invitee_id.eq.${user.id}');

      final ids = <String>{};
      for (final row in res as List) {
        final a = row['inviter_id']?.toString() ?? '';
        final b = row['invitee_id']?.toString() ?? '';
        if (a.isNotEmpty && a != user.id) ids.add(a);
        if (b.isNotEmpty && b != user.id) ids.add(b);
      }
      return ids.toList();
    } catch (e) {
      _log('getAcceptedInviteUserIds', e);
      return [];
    }
  }

  /// Streams the latest 20 location_points rows in real time.
  /// Used by map_provider to show live friend locations on the map.
  /// Filters to friends only happen in the provider, not here.
  Stream<List<Map<String, dynamic>>> getLocationStream() {
    return _client
        .from('location_points')
        .stream(primaryKey: ['id'])
        .order('recorded_at', ascending: false)
        .limit(20)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Future<List<UserNotification>> getUserNotifications() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (res as List).map((n) => UserNotification.fromJson(n)).toList();
    } catch (e) {
      _log('getUserNotifications', e);
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      _log('markNotificationAsRead', e);
    }
  }

  /// Sends an FCM push notification to [userId] via Firebase Cloud Messaging.
  /// Reads service account credentials from assets/service.json.
  Future<void> sendNotification(
    String userId,
    String title,
    String body, {
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
        },
      );
      if (response.status == 200) {
        return response.data;
      } else {
        _log('sendNotification', response.data);
      }
    } catch (e) {
      _log('sendNotification', e);
    }
  }

  void _log(String method, Object? error) {
    // Replace with your logger of choice (e.g. logger package).
    // ignore: avoid_print
    print('[SupabaseService.$method] $error');
  }
}
