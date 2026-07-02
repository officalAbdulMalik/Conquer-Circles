import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/services/auth/apple_auth_service.dart';
import 'package:test_steps/services/auth/google_auth_service.dart';
import '../models/invite_model.dart';
import '../models/notification_model.dart';
import '../models/profile_data_model.dart';
import '../models/walk_models.dart';
import '../models/dashboard_model.dart';

/// Central service for all Supabase interactions.
/// Every method is safe to call from any provider or screen.
class SupabaseService {
  static const oauthCallbackUrl = 'io.supabase.conquercircles://login-callback';

  final _client = Supabase.instance.client;
  late final AppleAuthService _appleAuthService = AppleAuthService(_client);
  late final GoogleAuthService _googleAuthService = GoogleAuthService(_client);

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get hasActiveUser => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) => _client.auth.signUp(
    email: email,
    password: password,
    data: {
      if (name != null && name.trim().isNotEmpty) 'full_name': name.trim(),
    },
  );

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String token,
  }) =>
      _client.auth.verifyOTP(email: email, token: token, type: OtpType.signup);

  Future<void> sendPasswordResetEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: oauthCallbackUrl,
    );
  }

  Future<UserResponse> updatePassword({required String password}) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> signInWithGoogle() async {
    await _googleAuthService.signIn(oauthCallbackUrl: oauthCallbackUrl);
  }

  Future<void> signInWithApple() async {
    await _appleAuthService.signIn(oauthCallbackUrl: oauthCallbackUrl);
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
  Future<void> ensureProfileExists({String? name}) async {
    final user = currentUser;
    if (user == null) return;
    try {
      final metadata = user.userMetadata ?? {};
      final metadataName =
          metadata['full_name']?.toString().trim().isNotEmpty == true
          ? metadata['full_name'].toString().trim()
          : metadata['name']?.toString().trim();
      final profileName = name?.trim().isNotEmpty == true
          ? name!.trim()
          : metadataName;
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _client.from('profiles').insert({
          'id': user.id,
          'username': profileName?.isNotEmpty == true
              ? profileName
              : user.email?.split('@').first ??
                    'User_${user.id.substring(0, 5)}',
          if (profileName?.isNotEmpty == true) 'full_name': profileName,
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

  /// Uploads a profile avatar to Supabase Storage and returns its public URL.
  /// Tries common bucket names and uses the first one that succeeds.
  Future<String> uploadProfileAvatar(
    Uint8List bytes, {
    required String fileExtension,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');
    if (bytes.isEmpty) throw Exception('Empty image payload');

    final normalizedExt = fileExtension.replaceAll('.', '').toLowerCase();
    final ext = normalizedExt.isEmpty ? 'jpg' : normalizedExt;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final objectPath = '${user.id}/$fileName';
    final contentType = _mimeTypeForExtension(ext);

    print(_client.auth.currentSession?.accessToken);


print(user.id);

    Object? lastError;
      try {
        await _client.storage
            .from('avatars')
            .uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(upsert: true, contentType: contentType),
            );
        return _client.storage.from('avatars').getPublicUrl(objectPath);
      } catch (e) {
        lastError = e;

        print('[SupabaseService.uploadProfileAvatar] Failed to upload to "avatars" bucket: $e');
      }
  
    throw Exception('Failed to upload avatar: $lastError');
  }

  String _mimeTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
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

  Future<Map<String, dynamic>> getTodayActivity() async {
    final user = currentUser;
    if (user == null) return const {};
    final date = DateTime.now().toIso8601String().split('T').first;
    try {
      final row = await _client
          .from('daily_steps')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', date)
          .maybeSingle();
      return row == null ? const {} : Map<String, dynamic>.from(row);
    } catch (e) {
      _log('getTodayActivity', e);
      return const {};
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

  Future<Map<String, dynamic>> syncWalkProgress({
    required int steps,
    required double distanceKm,
    required int durationSeconds,
  }) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};

    try {
      final response = await _client.rpc(
        'sync_walk_progress',
        params: {
          'p_steps_today': steps,
          'p_distance_km': distanceKm,
          'p_duration_seconds': durationSeconds,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('syncWalkProgress', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Persists today's steps when the richer walk-progress RPC is unavailable.
  Future<Map<String, dynamic>> syncDailyStepCount(int steps) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    final date = DateTime.now().toIso8601String().split('T').first;

    try {
      await _client.from('daily_steps').upsert({
        'user_id': user.id,
        'date': date,
        'steps': steps,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,date');
      return {'success': true};
    } catch (e) {
      _log('syncDailyStepCount', e);
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

  Future<LatLng?> getHomeBaseLocation() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final profile = await _client
          .from('profiles')
          .select('home_base_lat, home_base_lng')
          .eq('id', user.id)
          .maybeSingle();
      final lat = (profile?['home_base_lat'] as num?)?.toDouble();
      final lng = (profile?['home_base_lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (e) {
      _log('getHomeBaseLocation', e);
      return null;
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

  Future<void> updateGoals({
    required String weightGoal,
    required int dailyStepsGoal,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');
    try {
      await _client.from('profiles').update({
        'weight_goal': weightGoal,
        'step_goal': dailyStepsGoal,
        'daily_steps_goal': dailyStepsGoal,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      _log('updateGoals', e);
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
      return _getStepsDashboardDataFromDatabase();
    } catch (e) {
      _log('getStepsDashboardData', e);
      return _getStepsDashboardDataFromDatabase();
    }
  }

  Future<List<TerritoryHistoryEntry>> getTerritoryHistory({
    int limit = 20,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    try {
      final rows = await _selectTerritoryHistoryRows(user.id, limit: limit);

      return rows.map((rawRow) {
        final row = Map<String, dynamic>.from(rawRow);
        return TerritoryHistoryEntry.fromJson({
          ...row,
          'action': _resolveTerritoryHistoryAction(row),
          'is_defence':
              row['defender_id'] == user.id && row['attacker_id'] != user.id,
        });
      }).toList();
    } catch (e) {
      _log('getTerritoryHistory', e);
      rethrow;
    }
  }

  /// Returns one distance value per day for the signed-in user in the
  /// inclusive [from] to [to] date range.
  Future<List<DashboardDistanceDay>> getDistanceGraphData({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    if (toDate.isBefore(fromDate)) {
      throw ArgumentError(
        'The graph end date must not be before its start date',
      );
    }

    try {
      final rows = await _client
          .from('daily_steps')
          .select('*')
          .eq('user_id', user.id)
          .gte('date', _dateOnly(fromDate))
          .lte('date', _dateOnly(toDate))
          .order('date', ascending: true);

      final rowsByDate = <DateTime, DashboardDistanceDay>{};
      for (final rawRow in rows) {
        final row = Map<String, dynamic>.from(rawRow);
        final parsedDate = DateTime.tryParse(row['date']?.toString() ?? '');
        if (parsedDate == null) continue;

        final date = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
        final storedDistance = _readDoubleValue(
          row['distance_km'] ?? row['total_distance_km'],
        );
        final steps = _readIntValue(
          row['steps'] ?? row['step_count'] ?? row['total_steps'],
        );
        final distance = storedDistance > 0 ? storedDistance : steps * 0.00073;
        final storedDurationSeconds = _readIntValue(
          row['duration_seconds'] ??
              row['active_seconds'] ??
              row['walking_seconds'],
        );
        final durationSeconds = storedDurationSeconds > 0
            ? storedDurationSeconds
            : _estimatedDurationSeconds(steps);
        final previous = rowsByDate[date];

        rowsByDate[date] = DashboardDistanceDay(
          date: date,
          steps: (previous?.steps ?? 0) + steps,
          distanceKm: (previous?.distanceKm ?? 0) + distance,
          durationSeconds: (previous?.durationSeconds ?? 0) + durationSeconds,
        );
      }

      return List.generate(toDate.difference(fromDate).inDays + 1, (index) {
        final date = fromDate.add(Duration(days: index));
        return rowsByDate[date] ??
            DashboardDistanceDay(
              date: date,
              steps: 0,
              distanceKm: 0,
              durationSeconds: 0,
            );
      });
    } catch (e) {
      _log('getDistanceGraphData', e);
      rethrow;
    }
  }

  Future<List<DashboardDistanceDay>> getAllTimeDistanceGraphData() async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    try {
      final rows = await _client
          .from('daily_steps')
          .select('*')
          .eq('user_id', user.id)
          .lte('date', _dateOnly(DateTime.now()))
          .order('date', ascending: true);

      return _distanceDaysFromRows(rows);
    } catch (e) {
      _log('getAllTimeDistanceGraphData', e);
      rethrow;
    }
  }

  Future<List<DashboardTerritoryDay>> getTerritoryGraphData({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    if (toDate.isBefore(fromDate)) {
      throw ArgumentError(
        'The graph end date must not be before its start date',
      );
    }

    try {
      final rows = await _client
          .from('territory_attack_log')
          .select('created_at, territory_id, territory:territories(*)')
          .eq('attacker_id', user.id)
          .eq('captured', true)
          .gte('created_at', fromDate.toUtc().toIso8601String())
          .lt(
            'created_at',
            toDate.add(const Duration(days: 1)).toUtc().toIso8601String(),
          )
          .order('created_at', ascending: true);

      return _territoryDaysFromRows(
        rows,
        from: fromDate,
        to: toDate,
        fillMissingDays: true,
      );
    } catch (e) {
      _log('getTerritoryGraphData', e);
      rethrow;
    }
  }

  Future<List<DashboardTerritoryDay>> getAllTimeTerritoryGraphData() async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    try {
      final rows = await _client
          .from('territory_attack_log')
          .select('created_at, territory_id, territory:territories(*)')
          .eq('attacker_id', user.id)
          .eq('captured', true)
          .lte('created_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: true);

      return _territoryDaysFromRows(rows);
    } catch (e) {
      _log('getAllTimeTerritoryGraphData', e);
      rethrow;
    }
  }

  List<DashboardTerritoryDay> _territoryDaysFromRows(
    List<dynamic> rows, {
    DateTime? from,
    DateTime? to,
    bool fillMissingDays = false,
  }) {
    final areaByDate = <DateTime, double>{};
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final territory = _relatedTerritory(row['territory']);
      final capturedAt = DateTime.tryParse(
        row['capture_date']?.toString() ??
            row['capture_time']?.toString() ??
            row['captured_at']?.toString() ??
            row['created_at']?.toString() ??
            '',
      )?.toLocal();
      if (capturedAt == null) continue;

      final date = DateTime(capturedAt.year, capturedAt.month, capturedAt.day);
      final areaKm2 = _territoryAreaKm2(territory);
      areaByDate[date] = (areaByDate[date] ?? 0) + areaKm2;
    }

    if (fillMissingDays && from != null && to != null) {
      return List.generate(to.difference(from).inDays + 1, (index) {
        final date = from.add(Duration(days: index));
        return DashboardTerritoryDay(
          date: date,
          areaKm2: areaByDate[date] ?? 0,
        );
      });
    }

    return areaByDate.entries
        .map(
          (entry) =>
              DashboardTerritoryDay(date: entry.key, areaKm2: entry.value),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, dynamic> _relatedTerritory(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return const {};
  }

  double _territoryAreaKm2(Map<String, dynamic> territory) {
    final storedKm2 = _readDoubleValue(
      territory['area_km2'] ??
          territory['total_area_km2'] ??
          territory['captured_area_km2'],
    );
    if (storedKm2 > 0) return storedKm2;

    final storedM2 = _readDoubleValue(
      territory['area_m2'] ??
          territory['total_area_m2'] ??
          territory['captured_area_m2'],
    );
    if (storedM2 > 0) return storedM2 / 1000000;

    return _polygonAreaKm2(
      territory['geom'] ??
          territory['geometry'] ??
          territory['polygon'] ??
          territory['polygon_points'],
    );
  }

  double _polygonAreaKm2(Object? geometry) {
    Object? coordinates;
    if (geometry is Map) {
      coordinates = geometry['coordinates'] ?? geometry['polygon_points'];
    } else if (geometry is List) {
      coordinates = geometry;
    }

    if (coordinates is! List || coordinates.isEmpty) return 0;
    var ring = coordinates;
    while (ring.isNotEmpty &&
        ring.first is List &&
        (ring.first as List).isNotEmpty &&
        (ring.first as List).first is List) {
      ring = ring.first as List;
    }

    final points = <({double lat, double lng})>[];
    for (final rawPoint in ring) {
      if (rawPoint is Map) {
        final lat = _readDoubleValue(rawPoint['lat']);
        final lng = _readDoubleValue(rawPoint['lng']);
        points.add((lat: lat, lng: lng));
      } else if (rawPoint is List && rawPoint.length >= 2) {
        points.add((
          lat: _readDoubleValue(rawPoint[1]),
          lng: _readDoubleValue(rawPoint[0]),
        ));
      }
    }
    if (points.length < 3) return 0;

    const earthRadiusKm = 6371.0088;
    var area = 0.0;
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      area +=
          _degreesToRadians(next.lng - current.lng) *
          (2 +
              math.sin(_degreesToRadians(current.lat)) +
              math.sin(_degreesToRadians(next.lat)));
    }
    return (area * earthRadiusKm * earthRadiusKm / 2).abs();
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  List<DashboardDistanceDay> _distanceDaysFromRows(List<dynamic> rows) {
    final rowsByDate = <DateTime, DashboardDistanceDay>{};
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final parsedDate = DateTime.tryParse(row['date']?.toString() ?? '');
      if (parsedDate == null) continue;

      final date = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final storedDistance = _readDoubleValue(
        row['distance_km'] ?? row['total_distance_km'],
      );
      final steps = _readIntValue(
        row['steps'] ?? row['step_count'] ?? row['total_steps'],
      );
      final distance = storedDistance > 0 ? storedDistance : steps * 0.00073;
      final storedDurationSeconds = _readIntValue(
        row['duration_seconds'] ??
            row['active_seconds'] ??
            row['walking_seconds'],
      );
      final durationSeconds = storedDurationSeconds > 0
          ? storedDurationSeconds
          : _estimatedDurationSeconds(steps);
      final previous = rowsByDate[date];

      rowsByDate[date] = DashboardDistanceDay(
        date: date,
        steps: (previous?.steps ?? 0) + steps,
        distanceKm: (previous?.distanceKm ?? 0) + distance,
        durationSeconds: (previous?.durationSeconds ?? 0) + durationSeconds,
      );
    }

    return rowsByDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int _readIntValue(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDoubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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

  Future<Map<String, dynamic>> _getStepsDashboardDataFromDatabase() async {
    final user = currentUser;
    if (user == null) throw Exception('No active user');

    final today = DateTime.now().toIso8601String().split('T').first;
    final sevenDaysAgo = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).subtract(const Duration(days: 6)).toIso8601String().split('T').first;

    final profile =
        await _client
            .from('profiles')
            .select(
              'username, level, xp, xp_goal, step_goal, daily_streak, attack_energy',
            )
            .eq('id', user.id)
            .maybeSingle() ??
        <String, dynamic>{};

    final todayStepsRow = await _client
        .from('daily_steps')
        .select('steps')
        .eq('user_id', user.id)
        .eq('date', today)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final weeklyRows = await _client
        .from('daily_steps')
        .select('date, steps')
        .eq('user_id', user.id)
        .gte('date', sevenDaysAgo)
        .order('date', ascending: true);

    final badgesRows = await _client
        .from('user_badges')
        .select(
          'unlocked_at, badge:badges(id, number, name, description, category, icon)',
        )
        .eq('user_id', user.id)
        .order('unlocked_at', ascending: false);

    List<Map<String, dynamic>> territoryHistory = [];
    try {
      final historyRows = await _selectTerritoryHistoryRows(user.id);

      territoryHistory = historyRows.map((row) {
        final historyRow = Map<String, dynamic>.from(row);
        return {
          ...historyRow,
          'action': _resolveTerritoryHistoryAction(historyRow),
          'is_defence':
              historyRow['defender_id'] == user.id &&
              historyRow['attacker_id'] != user.id,
        };
      }).toList();
    } catch (e) {
      _log('getStepsDashboardData territory history fallback', e);
    }

    final steps = (todayStepsRow?['steps'] as num?)?.round() ?? 0;
    final calories = (steps * 0.04).round();
    final distanceKm = double.parse((steps * 0.00073).toStringAsFixed(2));
    final durationSeconds = _estimatedDurationSeconds(steps);
    final totalAreaKm2 = double.parse((distanceKm * 0.28).toStringAsFixed(1));
    final badges = badgesRows.map((row) {
      final badge = Map<String, dynamic>.from(row['badge'] as Map? ?? {});
      return {...badge, 'unlocked_at': row['unlocked_at']};
    }).toList();

    return {
      'profile': {
        'username':
            profile['username'] ?? user.email?.split('@').first ?? 'User',
        'level': profile['level'] ?? 1,
        'xp': profile['xp'] ?? 0,
        'xp_goal': profile['xp_goal'] ?? 1000,
        'step_goal': profile['step_goal'] ?? 10000,
        'streak': profile['daily_streak'] ?? 0,
        'attack_energy': profile['attack_energy'] ?? 0,
      },
      'today': {
        'steps': steps,
        'calories': calories,
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'total_area_km2': totalAreaKm2,
        'heart_rate': null,
      },
      'weekly_steps': weeklyRows,
      'badges': badges,
      'territory_history': territoryHistory,
    };
  }

  int _estimatedDurationSeconds(int steps) {
    if (steps <= 0) return 0;
    final minutes = (steps / 1160).round().clamp(1, 24 * 60);
    return (minutes * 60) + 39;
  }

  Future<List<dynamic>> _selectTerritoryHistoryRows(
    String userId, {
    int limit = 20,
  }) async {
    const baseColumns =
        'id, territory_id, attacker_id, defender_id, energy_used, energy_before, energy_after, captured, created_at';

    Future<List<dynamic>> query(String columns) {
      return _client
          .from('territory_attack_log')
          .select(columns)
          .or('attacker_id.eq.$userId,defender_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);
    }

    try {
      return await query('$baseColumns, action');
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      return query(baseColumns);
    }
  }

  String _resolveTerritoryHistoryAction(Map<String, dynamic> row) {
    final storedAction = row['action']?.toString().trim();
    if (storedAction?.isNotEmpty == true) {
      return storedAction!;
    }

    if (row['captured'] == true) {
      return 'captured';
    }

    final defenderId = row['defender_id']?.toString();
    if (defenderId == null || defenderId.isEmpty) {
      return 'claimed';
    }

    final energyBefore = _readIntValue(row['energy_before']);
    final energyAfter = _readIntValue(row['energy_after']);
    return energyAfter > energyBefore ? 'reinforced' : 'damaged';
  }

  // ---------------------------------------------------------------------------
  // Territory
  // ---------------------------------------------------------------------------

  /// Returns every territory within [radius] metres of [lat]/[lng].
  /// Visibility is intentionally not restricted to friends so the map can show
  /// the complete claimed-territory history for the viewed area.
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

      return raw.map((t) {
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

  Future<List<Territory>> getAllTerritories({
    double lat = 0,
    double lng = 0,
  }) async {
    final user = currentUser;
    try {
      final List<dynamic> raw = await _client.rpc(
        'get_territories_nearby',
        params: {'p_lat': lat, 'p_lng': lng, 'p_radius_m': 21000000},
      );

      return raw.map((t) {
        final territory = Territory.fromJson(t as Map<String, dynamic>);
        return user != null && t['user_id'] == user.id
            ? territory.copyWith(color: '#2196F3')
            : territory;
      }).toList();
    } catch (e) {
      _log('getAllTerritories', e);
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

  /// Updates metadata for one territory row.
  /// A user can own multiple disconnected territories, so this must target the
  /// territory ID rather than using user_id as an upsert conflict key.
  Future<void> upsertTerritoryMetadata(Territory territory) async {
    final user = currentUser;
    if (user == null) return;
    try {
      final profile = await getProfile();
      final username = profile?['username'] as String? ?? 'Conqueror';
      final json = territory.toJson()
        ..remove('id')
        ..remove('user_id')
        ..remove('geom')
        ..remove('polygon_points')
        ..['username'] = username
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('territories')
          .update(json)
          .eq('id', territory.id)
          .eq('user_id', user.id);
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
  /// [attackAreaGeoJson] is a GeoJSON MultiPoint/LineString of the attacker's
  /// walk route for this session. When supplied, a capture only carves out the
  /// part of the defender's territory the attacker actually covered (convex
  /// hull of the route) instead of taking the whole polygon.
  Future<Map<String, dynamic>> attackOrClaimTerritory({
    required String territoryId,
    required double speedKmh,
    required double lat,
    required double lng,
    String? attackAreaGeoJson,
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
          if (attackAreaGeoJson != null) 'p_attack_geom': attackAreaGeoJson,
        },
      );
      final result = Map<String, dynamic>.from(response as Map);
      return result;
    } catch (e) {
      _log('attackOrClaimTerritory', e);
      return {'action': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> mergeTouchingOwnedTerritories(
    String territoryId,
  ) async {
    try {
      final response = await _client.rpc(
        'merge_touching_owned_territories',
        params: {'p_territory_id': territoryId},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('mergeTouchingOwnedTerritories', e);
      return {'success': false, 'error': e.toString()};
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

  bool isProfileOnboardingComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    return profile['onboarding_completed'] == true &&
        profile['gender'] != null &&
        profile['age'] != null &&
        profile['height_cm'] != null &&
        profile['weight_kg'] != null;
  }

  Future<void> saveOnboardingProfile({
    required String? gender,
    required int age,
    required int weight,
    required String weightUnit,
    required int height,
    required String heightUnit,
    required String weightGoal,
    required int dailyStepsGoal,
    String? name,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');

    final fallbackUsername =
        user.email?.split('@').first ?? 'User_${user.id.substring(0, 5)}';
    final displayName = name?.trim();

    try {
      await ensureProfileExists(name: displayName);
      final existingProfile = await getProfile();
      final existingUsername = existingProfile?['username']?.toString().trim();
      await _client.from('profiles').upsert({
        'id': user.id,
        'username': existingUsername?.isNotEmpty == true
            ? existingUsername
            : displayName?.isNotEmpty == true
            ? displayName
            : fallbackUsername,
        if (displayName?.isNotEmpty == true) 'full_name': displayName,
        'gender': gender,
        'age': age,
        'weight_kg': weightUnit == 'kg'
            ? weight
            : (weight * 0.45359237).round(),
        'height_cm': heightUnit == 'cm' ? height : (height * 30.48).round(),
        'weight_unit': weightUnit,
        'height_unit': heightUnit,
        'weight_goal': weightGoal,
        'step_goal': dailyStepsGoal,
        'daily_steps_goal': dailyStepsGoal,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      _log('saveOnboardingProfile', e);
      rethrow;
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

  // ---------------------------------------------------------------------------
  // Leaderboard
  // ---------------------------------------------------------------------------

  Future<LeaderboardData> getSeasonLeaderboard({
    LeaderboardMetric metric = LeaderboardMetric.territoryTiles,
  }) async {
    final season = await _getLeaderboardSeason();
    final profiles = await _safeSelectList('profiles');
    final dailySteps = await _safeSelectList('daily_steps');
    final territories = await _safeSelectList('territories');
    final attackLogs = await _safeSelectList(
      'territory_attack_log',
      columns: 'attacker_id, defender_id, captured, created_at',
    );

    final currentUserId = currentUser?.id;
    final profileByUserId = <String, Map<String, dynamic>>{};
    for (final profile in profiles) {
      final id = _stringValue(profile['id'] ?? profile['user_id']);
      if (id != null) profileByUserId[id] = profile;
    }

    final statsByUserId = <String, _LeaderboardStats>{};
    _LeaderboardStats statsFor(String userId) {
      return statsByUserId.putIfAbsent(userId, () => _LeaderboardStats());
    }

    for (final row in dailySteps) {
      if (!_isWithinSeason(row['date'] ?? row['created_at'], season)) continue;
      final userId = _stringValue(row['user_id']);
      if (userId == null) continue;
      final steps = _intValue(row['steps']);
      final stats = statsFor(userId)..totalSteps += steps;
      final date = _dateKey(row['date'] ?? row['created_at']);
      if (steps > 0 && date != null) stats.activeWalkDates.add(date);
    }

    for (final row in territories) {
      if (!_isWithinSeason(
        row['capture_time'] ?? row['created_at'] ?? row['updated_at'],
        season,
        includeUnknownDates: true,
      )) {
        continue;
      }
      final userId = _stringValue(
        row['user_id'] ?? row['owner_id'] ?? row['claimed_by'],
      );
      if (userId == null) continue;
      final stats = statsFor(userId);
      stats.territoryTiles += 1;
      stats.territoryEnergy += _intValue(row['energy']);
    }

    for (final row in attackLogs) {
      if (!_isWithinSeason(row['created_at'], season)) continue;
      final attackerId = _stringValue(row['attacker_id']);
      final defenderId = _stringValue(row['defender_id']);
      final captured = row['captured'] == true;

      if (attackerId != null && attackerId != defenderId) {
        final attacker = statsFor(attackerId)..attacksStarted += 1;
        if (captured) attacker.raidsWon += 1;
      }

      if (defenderId != null && defenderId != attackerId && !captured) {
        statsFor(defenderId).defensesWon += 1;
      }
    }

    for (final userId in profileByUserId.keys) {
      final stats = statsFor(userId);
      if (userId == currentUserId) stats.isCurrentUser = true;
    }
    if (currentUserId != null) statsFor(currentUserId).isCurrentUser = true;

    final participants = <LeaderboardParticipant>[];
    for (final entry in statsByUserId.entries) {
      final userId = entry.key;
      final stats = entry.value;
      if (!stats.hasActivity && userId != currentUserId) continue;
      final profile = profileByUserId[userId];
      participants.add(
        LeaderboardParticipant(
          userId: userId,
          name: _leaderboardName(profile, userId),
          score: stats.scoreFor(metric),
          rank: 0,
          avatarUrl: _stringValue(profile?['avatar_url'] ?? profile?['avatar']),
          isCurrentUser: userId == currentUserId,
          territoryTiles: stats.territoryTiles,
          totalSteps: stats.totalSteps,
          raidsWon: stats.raidsWon,
          territoryEnergy: stats.territoryEnergy,
          attacksStarted: stats.attacksStarted,
          defensesWon: stats.defensesWon,
          activeWalkDays: stats.activeWalkDates.length,
        ),
      );
    }

    return LeaderboardData(
      season: season,
      participants: _rankParticipants(participants, metric),
      specialRankings: LeaderboardSpecialRankings(
        mostAggressive: _topSpecial(
          participants,
          (participant) => participant.attacksStarted,
        ),
        bestDefender: _topSpecial(
          participants,
          (participant) => participant.defensesWon,
        ),
        mostConsistent: _topSpecial(
          participants,
          (participant) => participant.activeWalkDays,
        ),
      ),
    );
  }

  Future<LeaderboardSeason> _getLeaderboardSeason() async {
    try {
      final row = await _client
          .from('seasons')
          .select()
          .eq('is_active', true)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row != null) return _leaderboardSeasonFromRow(row);
    } catch (e) {
      _log('getSeasonLeaderboard.season', e);
    }

    final now = DateTime.now();
    return LeaderboardSeason(
      name: 'Current Season',
      startedAt: DateTime(now.year, now.month),
    );
  }

  LeaderboardSeason _leaderboardSeasonFromRow(Map<String, dynamic> row) {
    return LeaderboardSeason(
      id: _stringValue(row['id']),
      name:
          _stringValue(row['name'] ?? row['title'] ?? row['season_name']) ??
          'Current Season',
      startedAt: _dateTimeValue(row['started_at'] ?? row['start_date']),
      endsAt: _dateTimeValue(
        row['ends_at'] ?? row['ended_at'] ?? row['end_date'],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _safeSelectList(
    String table, {
    String columns = '*',
  }) async {
    try {
      final rows = await _client.from(table).select(columns);
      return (rows as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (e) {
      _log('getSeasonLeaderboard.$table', e);
      return [];
    }
  }

  List<LeaderboardParticipant> _rankParticipants(
    List<LeaderboardParticipant> participants,
    LeaderboardMetric metric,
  ) {
    final sorted = [...participants]
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return [
      for (var index = 0; index < sorted.length; index++)
        sorted[index].copyWith(
          rank: index + 1,
          score: sorted[index].scoreFor(metric),
          medal: index == 0
              ? '🥇'
              : index == 1
              ? '🥈'
              : index == 2
              ? '🥉'
              : null,
        ),
    ];
  }

  LeaderboardParticipant? _topSpecial(
    List<LeaderboardParticipant> participants,
    int Function(LeaderboardParticipant participant) readValue,
  ) {
    final ranked = participants.where((item) => readValue(item) > 0).toList()
      ..sort((a, b) {
        final byValue = readValue(b).compareTo(readValue(a));
        if (byValue != 0) return byValue;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return ranked.isEmpty ? null : ranked.first;
  }

  bool _isWithinSeason(
    Object? value,
    LeaderboardSeason season, {
    bool includeUnknownDates = false,
  }) {
    final date = _dateTimeValue(value);
    if (date == null) return includeUnknownDates;
    final start = season.startedAt;
    final end = season.endsAt;
    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  String _leaderboardName(Map<String, dynamic>? profile, String userId) {
    return _stringValue(
          profile?['username'] ??
              profile?['full_name'] ??
              profile?['name'] ??
              profile?['display_name'],
        ) ??
        (userId == currentUser?.id
            ? currentUser?.email?.split('@').first
            : null) ??
        'Player ${userId.substring(0, math.min(4, userId.length)).toUpperCase()}';
  }

  String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int _intValue(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateTimeValue(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  String? _dateKey(Object? value) {
    final date = _dateTimeValue(value);
    if (date == null) return null;
    return '${date.year}-${date.month}-${date.day}';
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

class _LeaderboardStats {
  int territoryTiles = 0;
  int totalSteps = 0;
  int raidsWon = 0;
  int territoryEnergy = 0;
  int attacksStarted = 0;
  int defensesWon = 0;
  bool isCurrentUser = false;
  final Set<String> activeWalkDates = <String>{};

  bool get hasActivity {
    return territoryTiles > 0 ||
        totalSteps > 0 ||
        raidsWon > 0 ||
        territoryEnergy > 0 ||
        attacksStarted > 0 ||
        defensesWon > 0 ||
        activeWalkDates.isNotEmpty;
  }

  int scoreFor(LeaderboardMetric metric) {
    switch (metric) {
      case LeaderboardMetric.territoryTiles:
        return territoryTiles;
      case LeaderboardMetric.totalSteps:
        return totalSteps;
      case LeaderboardMetric.raidsWon:
        return raidsWon;
      case LeaderboardMetric.territoryEnergy:
        return territoryEnergy;
    }
  }
}
