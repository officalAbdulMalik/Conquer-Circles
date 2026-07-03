import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/map_model.dart';
import '../models/walk_models.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/game_service.dart';
import '../services/dashboard_service.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class MapNotifier extends StateNotifier<MapState> {
  final SupabaseService _service;
  final GameService _gameService;
  final Ref _ref;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _progressSyncTimer;
  int? _pedometerBaseline;
  int _pedometerStepOffset = 0;
  bool _sensorHasCountedSteps = false;
  bool _isSyncingProgress = false;
  int _stepsBeforeRun = 0;
  double _distanceBeforeRun = 0;
  int _durationBeforeRun = 0;
  DateTime? _runStartedAt;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartedAt;
  Position? _lastAcceptedRunPosition;
  LatLng? _lastTerritoryRefreshLocation;
  DateTime? _lastTerritoryRefreshAt;
  bool _territoryRefreshInProgress = false;
  bool _allTerritoriesLoaded = false;
  int _lastSyncedRunSteps = 0;
  final Map<String, Timer> _underAttackTimers = {};

  supabase.User? get currentUser => _service.currentUser;

  MapNotifier(this._service, this._gameService, this._ref) : super(MapState()) {
    initialize();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize({bool forceRequest = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    await _loadAccountMapData().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        developer.log('[Map] Account map data bootstrap timed out.');
      },
    );

    // Device-level location services. Requesting app permission won't turn the
    // service back on, so we don't prompt here — just surface a message later.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // Only ever prompt when permission has NOT been granted yet. If the user
    // already allowed it (whileInUse / always) we never re-ask, so restarting
    // the app won't keep showing the system dialog.
    var permission = await Geolocator.checkPermission();
    final alreadyGranted =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (!alreadyGranted) {
      if (permission == LocationPermission.denied) {
        // Not decided yet (or an iOS "Allow Once" grant expired) — ask once.
        permission = await Geolocator.requestPermission();
      } else if (forceRequest &&
          permission == LocationPermission.deniedForever) {
        // The OS won't show the dialog again; a user-initiated "Enable" tap
        // sends them to Settings instead.
        await Geolocator.openAppSettings();
        permission = await Geolocator.checkPermission();
      }
    }

    final granted =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (!granted) {
      state = state.copyWith(
        isLoading: false,
        permissionGranted: false,
        error: !serviceEnabled
            ? 'Turn on location services to use map features.'
            : 'Location permission denied. Map features limited.',
      );
      // Even if denied, we can still fall back to a saved home base if present.
      if (state.homeBase != null) {
        state = state.copyWith(isLoading: false);
      }
      return;
    }

    state = state.copyWith(permissionGranted: true);

    try {
      // Fetch current position with a 10-second timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(
        userLocation: LatLng(position.latitude, position.longitude),
        isLoading: false,
      );
      await _loadTerritoriesAround(state.userLocation!);
    } catch (e) {
      developer.log('[Map] Initialization timeout or error: $e');

      state = state.copyWith(
        isLoading: false,
        error: state.userLocation == null ? 'GPS location unavailable.' : null,
      );
      final fallbackLocation = state.userLocation ?? state.homeBase;
      if (fallbackLocation != null) {
        await _loadTerritoriesAround(fallbackLocation);
      }
    }

    _startLocationTracking();
  }

  Future<void> _loadAccountMapData() async {
    final homeBase = await _service.getHomeBaseLocation().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    var attackEnergy = state.currentAttackEnergy;

    try {
      final dashboard = await _service.getStepsDashboardData().timeout(
        const Duration(seconds: 6),
      );
      final profile = dashboard['profile'];
      if (profile is Map) {
        attackEnergy =
            (profile['attack_energy'] as num?)?.round() ?? attackEnergy;
      }
    } catch (e) {
      try {
        attackEnergy = await _service.getAttackEnergy().timeout(
          const Duration(seconds: 4),
        );
      } catch (_) {
        attackEnergy = state.currentAttackEnergy;
      }
      developer.log('[Map] Dashboard bootstrap failed: $e');
    }

    state = state.copyWith(
      homeBase: homeBase,
      currentAttackEnergy: attackEnergy,
    );
  }

  Future<void> requestPermission() async {
    await initialize(forceRequest: true);
  }

  // ---------------------------------------------------------------------------
  // Foreground location tracking
  // ---------------------------------------------------------------------------

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_handleLocationUpdate);
  }

  Future<void> startRun() async {
    final initialRoute = state.userLocation == null
        ? const <LatLng>[]
        : <LatLng>[state.userLocation!];
    state = state.copyWith(
      isRunActive: true,
      isRunPaused: false,
      runRoute: initialRoute,
      trailPoints: initialRoute,
      runDistanceKm: 0,
      runSteps: 0,
      runClaimedAreaKm2: 0,
      runClaimedTerritoryIds: const {},
      runStartedAt: DateTime.now(),
      clearRunPausedAt: true,
    );

    final today = await _service.getTodayActivity();
    _stepsBeforeRun = _readInt(today['steps']);
    _distanceBeforeRun = _readDouble(
      today['distance_km'] ?? today['total_distance_km'],
    );
    _durationBeforeRun = _readInt(
      today['duration_seconds'] ??
          today['active_seconds'] ??
          today['walking_seconds'],
    );
    _pedometerBaseline = null;
    _pedometerStepOffset = 0;
    _sensorHasCountedSteps = false;
    _runStartedAt = DateTime.now();
    _pausedDuration = Duration.zero;
    _pauseStartedAt = null;
    _lastAcceptedRunPosition = null;
    _lastSyncedRunSteps = 0;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        developer.log(
          '[Map] Activity recognition permission was not granted; '
          'using validated GPS distance for step estimates.',
        );
      }
    }

    await _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen(
      _handleStepCount,
      onError: _handleStepCountError,
    );
  }

  void pauseRun() {
    if (!state.isRunActive || state.isRunPaused) return;
    _pauseStartedAt = DateTime.now();
    state = state.copyWith(isRunPaused: true, runPausedAt: DateTime.now());
  }

  void resumeRun() {
    if (!state.isRunActive || !state.isRunPaused) return;
    final pauseStartedAt = _pauseStartedAt;
    if (pauseStartedAt != null) {
      _pausedDuration += DateTime.now().difference(pauseStartedAt);
    }
    _pauseStartedAt = null;
    // Shift the display anchor forward by the pause length so the on-screen
    // timer excludes paused time.
    final pausedAt = state.runPausedAt;
    final shiftedStart = (pausedAt != null && state.runStartedAt != null)
        ? state.runStartedAt!.add(DateTime.now().difference(pausedAt))
        : state.runStartedAt;
    state = state.copyWith(
      isRunPaused: false,
      runStartedAt: shiftedStart,
      clearRunPausedAt: true,
    );
  }

  Future<void> finishRun() async {
    if (!state.isRunActive) return;
    _progressSyncTimer?.cancel();
    await _syncRunProgress(force: true);
    // Steps are now persisted — let the add-badge function check step badges
    // (Step Rookie, Daily Grinder, Marathon Walker, Consistency Hero, ...).
    unawaited(_service.checkAndAwardBadges('steps_synced'));
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    _pedometerBaseline = null;
    _pedometerStepOffset = 0;
    _sensorHasCountedSteps = false;
    _runStartedAt = null;
    _pauseStartedAt = null;
    _lastAcceptedRunPosition = null;
    _pausedDuration = Duration.zero;
    state = state.copyWith(
      isRunActive: false,
      isRunPaused: false,
      trailPoints: const <LatLng>[],
      clearRunStartedAt: true,
      clearRunPausedAt: true,
    );
    await loadAllTerritories(force: true);
    await _refreshDashboardAfterMapActivity();
  }

  Future<void> persistRunProgress() => _syncRunProgress(force: true);

  void _handleStepCount(StepCount event) {
    if (!state.isRunActive) return;
    if (_pedometerBaseline == null) {
      _pedometerBaseline = event.steps;
      _pedometerStepOffset = state.runSteps;
    }
    if (state.isRunPaused) return;

    final sensorSteps = math.max(0, event.steps - _pedometerBaseline!);
    if (sensorSteps > 0) _sensorHasCountedSteps = true;
    final runSteps = math.max(
      state.runSteps,
      _pedometerStepOffset + sensorSteps,
    );
    if (runSteps == state.runSteps) return;
    state = state.copyWith(runSteps: runSteps);
    _scheduleRunProgressSync();
  }

  void _handleStepCountError(Object error) {
    developer.log('[Map] Pedometer stream error: $error');
    _sensorHasCountedSteps = false;
  }

  // ---------------------------------------------------------------------------
  // Territory loading
  // ---------------------------------------------------------------------------

  /// Called on camera idle — loads all existing territories so the app
  /// displays every territory instead of only the nearby ones.
  Future<void> loadTerritoriesForBounds(LatLngBounds bounds) async {
    await loadAllTerritories();
  }

  Future<void> loadAllTerritories({bool force = false}) async {
    if (_allTerritoriesLoaded && !force) return;
    try {
      final fresh = await _service.getAllTerritories(
        lat: state.userLocation?.latitude ?? 0,
        lng: state.userLocation?.longitude ?? 0,
      );
      state = state.copyWith(nearbyTerritories: fresh);
      _allTerritoriesLoaded = true;
    } catch (e) {
      developer.log('[Map] loadAllTerritories error: $e');
    }
  }

  Future<void> _loadTerritoriesAround(LatLng location) async {
    await loadAllTerritories();
  }

  Future<void> getCurrentLocation() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      state = state.copyWith(
        userLocation: LatLng(pos.latitude, pos.longitude),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not fetch location: $e',
      );
    }
  }

  Future<Map<String, dynamic>> setHomeBaseToCurrentLocation() async {
    var location = state.userLocation;
    if (location == null) {
      await getCurrentLocation();
      location = state.userLocation;
    }

    if (location == null) {
      return {'success': false, 'error': 'Current location is unavailable.'};
    }

    return setHomeBase(location);
  }

  Future<Map<String, dynamic>> setHomeBase(LatLng location) async {
    final result = await _gameService
        .setHomeBase(location.latitude, location.longitude)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => {
            'success': false,
            'error': 'Setting home base timed out. Please try again.',
          },
        );

    if (result['success'] == true) {
      state = state.copyWith(homeBase: location, error: null);
      await _loadTerritoriesAround(location);
    } else {
      state = state.copyWith(error: result['error']?.toString());
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Location updates and territory entry
  // ---------------------------------------------------------------------------

  // Tracks last territory processed to avoid calling the RPC on every GPS tick
  String? _lastProcessedTerritoryId;

  void _handleLocationUpdate(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    final speedKmh = position.speed * 3.6; // m/s → km/h

    state = state.copyWith(
      userLocation: latLng,
      currentSpeedMps: position.speed,
      currentSpeedKmh: speedKmh,
    );

    if (state.isRunActive && !state.isRunPaused) {
      _appendRunLocation(position, latLng);
      _appendTrailPoint(position, latLng);
    }

    final user = _service.currentUser;
    if (user == null) return;

    _checkCrossingNotifications(latLng, user.id);
    _refreshTerritoriesIfNeeded(latLng);

    // ── Territory action: process only when user is inside a real polygon ──
    // Only fires when speed is in valid walk range (2–15 km/h)
    if (state.isRunActive &&
        !state.isRunPaused &&
        speedKmh >= 2 &&
        speedKmh <= 15) {
      final territory = _territoryAtPoint(latLng);
      if (territory == null) {
        _lastProcessedTerritoryId = null;
        return;
      }

      if (territory.id != _lastProcessedTerritoryId) {
        _lastProcessedTerritoryId = territory.id;
        _processTerritoryEntry(territory.id, latLng, speedKmh);
      }
    }
  }

  void _appendRunLocation(Position position, LatLng location) {
    if (position.accuracy > 25) return;

    final previousPosition = _lastAcceptedRunPosition;
    if (previousPosition == null) {
      _lastAcceptedRunPosition = position;
      if (state.runRoute.isEmpty) {
        state = state.copyWith(runRoute: [location]);
      }
      return;
    }

    final distanceMeters = Geolocator.distanceBetween(
      previousPosition.latitude,
      previousPosition.longitude,
      location.latitude,
      location.longitude,
    );
    final elapsedSeconds =
        position.timestamp
            .difference(previousPosition.timestamp)
            .inMilliseconds /
        1000;
    if (elapsedSeconds <= 0) return;

    final gpsSpeedKmh = math.max(position.speed, 0) * 3.6;
    final derivedSpeedKmh = distanceMeters / elapsedSeconds * 3.6;
    final minimumDistance = math.max(5.0, position.accuracy * 0.6);

    final isReliableWalk =
        gpsSpeedKmh >= 1.8 &&
        gpsSpeedKmh <= 15 &&
        derivedSpeedKmh >= 1.0 &&
        derivedSpeedKmh <= 18 &&
        distanceMeters >= minimumDistance &&
        distanceMeters <= 100;
    if (!isReliableWalk) {
      _lastAcceptedRunPosition = position;
      return;
    }

    _lastAcceptedRunPosition = position;
    final runDistanceKm = state.runDistanceKm + distanceMeters / 1000;
    final estimatedSteps = (runDistanceKm * 1000 / 0.75).floor();
    final runSteps = _sensorHasCountedSteps
        ? state.runSteps
        : math.max(state.runSteps, estimatedSteps);

    state = state.copyWith(
      runRoute: [...state.runRoute, location],
      runDistanceKm: runDistanceKm,
      runSteps: runSteps,
    );
    _scheduleRunProgressSync();
  }

  /// Records a point for the visual walking trail. Unlike [_appendRunLocation]
  /// this is NOT speed-gated, so it faithfully captures turnarounds and pauses
  /// (where the walker slows to change direction). Light distance de-duping
  /// keeps GPS jitter out while preserving every real corner of the path.
  void _appendTrailPoint(Position position, LatLng location) {
    if (position.accuracy > 30) return;

    final trail = state.trailPoints;
    if (trail.isEmpty) {
      state = state.copyWith(trailPoints: <LatLng>[location]);
      return;
    }

    final last = trail.last;
    final distanceMeters = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      location.latitude,
      location.longitude,
    );
    // Ignore near-duplicate jitter, but keep everything else (including the
    // slow turnaround point that runRoute's speed filter would drop).
    if (distanceMeters < 3 || distanceMeters > 200) return;

    state = state.copyWith(trailPoints: <LatLng>[...trail, location]);
  }

  Territory? _territoryAtPoint(LatLng point) {
    for (final territory in state.nearbyTerritories) {
      if (!territory.hasPolygon) continue;
      if (_isPointInTerritory(point, territory)) {
        return territory;
      }
    }
    return null;
  }

  /// Point-in-territory test across ALL parts of a (possibly merged)
  /// territory, respecting holes: inside the exterior ring of any part and
  /// not inside one of that part's holes.
  bool _isPointInTerritory(LatLng point, Territory territory) {
    for (final part in territory.renderParts) {
      if (part.isEmpty) continue;
      if (!_isPointInPolygon(point, part.first)) continue;
      var inHole = false;
      for (var i = 1; i < part.length; i++) {
        if (_isPointInPolygon(point, part[i])) {
          inHole = true;
          break;
        }
      }
      if (!inHole) return true;
    }
    return false;
  }

  /// Processes territory entry: validates conditions then calls attack RPC.
  /// Includes app-side validation for speed, protection, shield, cooldown.
  Future<void> _processTerritoryEntry(
    String territoryId,
    LatLng location,
    double speedKmh,
  ) async {
    // ── APP-SIDE VALIDATION 1: SPEED CHECK ────────────────────────────────
    if (speedKmh < 2.0 || speedKmh > 15.0) {
      state = state.copyWith(
        lastAttackResult: {
          'action': 'error',
          'reason': 'invalid_speed',
          'speed_kmh': speedKmh,
          'message':
              'Walking speed required (2-15 km/h). Current: ${speedKmh.toStringAsFixed(1)} km/h',
        },
      );
      return;
    }

    // ── APP-SIDE VALIDATION 2: FIND TERRITORY IN NEARBY ────────────────────
    Territory? territory;
    try {
      territory = state.nearbyTerritories.firstWhere(
        (t) => t.id == territoryId,
      );
    } catch (_) {
      territory = null;
    }

    if (territory == null) {
      state = state.copyWith(
        lastAttackResult: {
          'action': 'error',
          'reason': 'territory_not_found',
          'message': 'Territory not found nearby',
        },
      );
      return;
    }

    // ── SERVER-SIDE VALIDATION - protection, shield, and cooldown are final.
    // The server will return a protected/shielded response for walks that
    // did not change territory ownership or energy.

    // ── APP-SIDE VALIDATION 5: CHECK COOLDOWN ────────────────────────────
    // Note: Could check local cache or just let RPC verify
    // For now, we let RPC verify this (security gate)

    // ── APP-SIDE VALIDATION 6: ENERGY CHECK ──────────────────────────────
    debugPrint('🔋 [Attack] Energy check: ${state.currentAttackEnergy} <= 0?');
    if (state.currentAttackEnergy <= 0) {
      debugPrint('❌ [Attack] NO ENERGY - Attack blocked');
      state = state.copyWith(
        lastAttackResult: {
          'action': 'no_energy',
          'reason': 'insufficient_attack_energy',
          'current_energy': state.currentAttackEnergy,
          'message': '⚡ No attack energy! Walk more to generate energy.',
        },
      );
      return;
    }

    // ── ALL APP-SIDE CHECKS PASSED → CALL RPC ────────────────────────────
    debugPrint('🚀 [Attack] Calling RPC with:');
    debugPrint('  Territory: $territoryId');
    debugPrint('  Speed: $speedKmh km/h');
    debugPrint('  Location: ${location.latitude}, ${location.longitude}');
    debugPrint('  Current Energy: ${state.currentAttackEnergy}');

    final result = await _service.attackOrClaimTerritory(
      territoryId: territoryId,
      speedKmh: speedKmh,
      lat: location.latitude,
      lng: location.longitude,
      attackAreaGeoJson: _runRouteAsGeoJson(),
    );

    debugPrint('✅ [Attack] RPC Result: $result');

    await _handleAttackResult(result, location);
  }

  /// Serialises the current walk route as a GeoJSON MultiPoint so the server
  /// can carve out only the area the attacker covered (convex hull of the
  /// route) instead of transferring the defender's entire territory.
  /// Returns null when the route is too short to form an area, in which case
  /// the server falls back to a full-territory capture.
  String? _runRouteAsGeoJson() {
    final route = state.runRoute;
    if (route.length < 3) return null;
    final coordinates = route
        .map((point) => '[${point.longitude},${point.latitude}]')
        .join(',');
    return '{"type":"MultiPoint","coordinates":[$coordinates]}';
  }

  /// Centralised logic for handling attack/claim results, including
  /// state updates, notifications, and map refreshes.
  Future<void> _handleAttackResult(
    Map<String, dynamic> result,
    LatLng location,
  ) async {
    final action = result['action'] as String?;
    if (action == null) return;
    var territoryId = result['territory_id'] as String?;
    final claimedComponentId = territoryId;

    if ((action == 'claimed' || action == 'captured') && territoryId != null) {
      final mergeResult = await _service.mergeTouchingOwnedTerritories(
        territoryId,
      );
      final mergedTerritoryId = mergeResult['territory_id']?.toString();
      if (mergeResult['success'] == true &&
          mergedTerritoryId != null &&
          mergedTerritoryId.isNotEmpty) {
        territoryId = mergedTerritoryId;
        result = {...result, 'territory_id': mergedTerritoryId};
      }
    }

    // Push result into state so the UI (MapView) can react with toasts/animations
    state = state.copyWith(lastAttackResult: result);

    if (territoryId != null && (action == 'damaged' || action == 'captured')) {
      _markTerritoryUnderAttack(territoryId);
    }

    // ── UPDATE ATTACK ENERGY DISPLAY ───────────────────────────────────────
    // Reload attack energy to reflect any deductions from this attack
    if (action == 'captured' ||
        action == 'damaged' ||
        action == 'reinforced' ||
        action == 'claimed') {
      final updatedEnergy = await _service.getAttackEnergy();
      state = state.copyWith(currentAttackEnergy: updatedEnergy);
    }

    // ── REFRESH TERRITORY DATA AFTER ATTACK ────────────────────────────────
    if (territoryId != null &&
        (action == 'captured' ||
            action == 'damaged' ||
            action == 'reinforced' ||
            action == 'claimed')) {
      // Reload all territories after an attack so the map reflects ownership
      // and energy updates everywhere.
      await loadAllTerritories(force: true);
    }

    if (action == 'captured' ||
        action == 'damaged' ||
        action == 'reinforced' ||
        action == 'claimed') {
      unawaited(_refreshDashboardAfterMapActivity(optimisticResult: result));
    }

    if (action == 'claimed' || action == 'captured') {
      _recordRunTerritory(claimedComponentId);
      await _service.checkAndAwardBadges('territory_captured', result);
    } else if (action == 'reinforced') {
      await _service.checkAndAwardBadges('territory_reinforced', result);
    }

    // ── Notifications ────────────────────────────────────────────────────────
    if (action == 'captured') {
      // Notify involved parties via FCM
      if (result['previous_owner_id'] != null) {
        final victimUsername =
            result['previous_owner_username'] as String? ?? 'A rival';
        final myName = result['username'] as String? ?? 'Someone';

        // Notify attacker (victory)
        await NotificationService.notifyRaidVictory(
          currentUser!.id,
          victimUsername,
        );
        // Notify defender (lost)
        await NotificationService.notifyTerritoryLost(
          result['previous_owner_id'],
          myName,
        );
      }
    } else if (action == 'damaged') {
      // Notify defender they are being attacked
      final defenderId = result['defender_id']?.toString();
      if (defenderId != null && defenderId.isNotEmpty) {
        await NotificationService.notifyTerritoryUnderAttack(defenderId);
      }
    }
  }

  void _markTerritoryUnderAttack(String territoryId) {
    _underAttackTimers.remove(territoryId)?.cancel();
    state = state.copyWith(
      underAttackTerritoryIds: {...state.underAttackTerritoryIds, territoryId},
    );
    _underAttackTimers[territoryId] = Timer(const Duration(seconds: 10), () {
      final nextIds = {...state.underAttackTerritoryIds}..remove(territoryId);
      state = state.copyWith(underAttackTerritoryIds: nextIds);
      _underAttackTimers.remove(territoryId);
    });
  }

  Future<void> _refreshDashboardAfterMapActivity({
    Map<String, dynamic>? optimisticResult,
  }) {
    return _ref
        .read(dashboardProvider.notifier)
        .refreshAfterMapActivity(optimisticResult: optimisticResult);
  }

  void _recordRunTerritory(String? territoryId) {
    if (!state.isRunActive ||
        territoryId == null ||
        state.runClaimedTerritoryIds.contains(territoryId)) {
      return;
    }

    Territory? territory;
    for (final item in state.nearbyTerritories) {
      if (item.id == territoryId) {
        territory = item;
        break;
      }
    }

    state = state.copyWith(
      runClaimedTerritoryIds: {...state.runClaimedTerritoryIds, territoryId},
      runClaimedAreaKm2: state.runClaimedAreaKm2 + _territoryAreaKm2(territory),
    );
  }

  /// Total area across all parts of a territory, subtracting holes.
  double _territoryAreaKm2(Territory? territory) {
    if (territory == null) return 0;
    var total = 0.0;
    for (final part in territory.renderParts) {
      if (part.isEmpty) continue;
      total += _polygonAreaKm2(part.first);
      for (var i = 1; i < part.length; i++) {
        total -= _polygonAreaKm2(part[i]);
      }
    }
    return total < 0 ? 0 : total;
  }

  double _polygonAreaKm2(List<LatLng>? points) {
    if (points == null || points.length < 3) return 0;
    const earthRadiusKm = 6371.0088;
    var area = 0.0;
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      area +=
          (next.longitude - current.longitude) *
          math.pi /
          180 *
          (2 +
              math.sin(current.latitude * math.pi / 180) +
              math.sin(next.latitude * math.pi / 180));
    }
    return (area * earthRadiusKm * earthRadiusKm / 2).abs();
  }

  Future<void> _syncRunProgress({bool force = false}) async {
    if (!state.isRunActive) {
      return;
    }
    if (_isSyncingProgress) {
      if (!force) return;
      while (_isSyncingProgress) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    if (!state.isRunActive ||
        (!force && state.runSteps == _lastSyncedRunSteps)) {
      return;
    }
    _isSyncingProgress = true;
    final runSteps = state.runSteps;
    final stepsToday = _stepsBeforeRun + runSteps;
    try {
      var result = await _service.syncWalkProgress(
        steps: stepsToday,
        distanceKm: _distanceBeforeRun + state.runDistanceKm,
        durationSeconds: _durationBeforeRun + _activeRunDuration().inSeconds,
      );
      if (result['success'] != true) {
        developer.log(
          '[Map] sync_walk_progress failed; saving step count directly: '
          '${result['error']}',
        );
        result = await _service.syncDailyStepCount(stepsToday);
      }
      if (result['success'] == true) {
        _lastSyncedRunSteps = runSteps;
      }
      final energy = result['attack_energy'];
      if (energy is num) {
        state = state.copyWith(currentAttackEnergy: energy.round());
      }
    } finally {
      _isSyncingProgress = false;
    }
  }

  void _scheduleRunProgressSync() {
    if (!state.isRunActive || state.runSteps == _lastSyncedRunSteps) return;
    _progressSyncTimer?.cancel();
    _progressSyncTimer = Timer(const Duration(seconds: 5), _syncRunProgress);
  }

  Duration _activeRunDuration() {
    final startedAt = _runStartedAt;
    if (startedAt == null) return Duration.zero;
    final end = state.isRunPaused
        ? _pauseStartedAt ?? DateTime.now()
        : DateTime.now();
    return end.difference(startedAt) - _pausedDuration;
  }

  int _readInt(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Territory action — called from map territory interactions
  // ---------------------------------------------------------------------------

  /// Public method for UI to manually trigger a territory action.
  /// Called from territory tap or automated GPS entry.
  Future<Map<String, dynamic>?> onEnterTerritory(String territoryId) async {
    final speedKmh = state.currentSpeedKmh;
    if (state.userLocation == null) return null;

    // Delegate to territory entry handler which includes all validation
    await _processTerritoryEntry(territoryId, state.userLocation!, speedKmh);
    return state.lastAttackResult;
  }

  // ---------------------------------------------------------------------------
  // Shield
  // ---------------------------------------------------------------------------

  Future<void> activateShield(String territoryId) async {
    final user = _service.currentUser;
    if (user == null) return;

    final territory = state.nearbyTerritories
        .where((t) => t.id == territoryId)
        .firstOrNull;
    if (territory == null || territory.userId != user.id) return;

    final updated = territory.copyWith(
      shieldUntil: DateTime.now().add(const Duration(days: 7)),
    );

    state = state.copyWith(
      nearbyTerritories: [
        for (final t in state.nearbyTerritories)
          t.id == territoryId ? updated : t,
      ],
    );

    try {
      await _service.upsertTerritoryMetadata(updated);
    } catch (e) {
      developer.log('[Shield] Failed to activate: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Polygon helpers
  // ---------------------------------------------------------------------------

  void _checkCrossingNotifications(LatLng point, String userId) {
    final newInsideIds = <String>{};
    final currentInsideIds = Set<String>.from(
      state.currentlyInsideTerritoryIds,
    );

    for (final territory in state.nearbyTerritories) {
      if (territory.userId == userId) continue;
      if (!territory.hasPolygon) continue;
      if (_isPointInTerritory(point, territory)) {
        newInsideIds.add(territory.id);
        // Only notify on first entry — not on every GPS update
        if (!currentInsideIds.contains(territory.id)) {
          _sendCrossingNotification(territory);
        }
      }
    }

    state = state.copyWith(currentlyInsideTerritoryIds: newInsideIds);
  }

  void _refreshTerritoriesIfNeeded(LatLng location) {
    if (_territoryRefreshInProgress) return;

    const refreshDistanceMeters = 200.0;
    const refreshInterval = Duration(seconds: 30);

    final lastLocation = _lastTerritoryRefreshLocation;
    final lastRefreshAt = _lastTerritoryRefreshAt;
    if (lastLocation != null && lastRefreshAt != null) {
      final distance = Geolocator.distanceBetween(
        lastLocation.latitude,
        lastLocation.longitude,
        location.latitude,
        location.longitude,
      );
      if (distance < refreshDistanceMeters &&
          DateTime.now().difference(lastRefreshAt) < refreshInterval) {
        return;
      }
    }

    _lastTerritoryRefreshLocation = location;
    _lastTerritoryRefreshAt = DateTime.now();
    _territoryRefreshInProgress = true;

    unawaited(
      _loadTerritoriesAround(location).whenComplete(() {
        _territoryRefreshInProgress = false;
      }),
    );
  }

  Future<void> _sendCrossingNotification(Territory territory) async {
    try {
      final profile = await _service.getProfile();
      final visitorName = profile?['username'] as String? ?? 'A rival';
      await NotificationService.notifyRivalNearby(
        ownerUserId: territory.userId,
        rivalUsername: visitorName,
      );
    } catch (e) {
      developer.log('[Map] _sendCrossingNotification error: $e');
    }
  }

  /// Ray-casting algorithm — works for any convex or concave polygon.
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude > point.longitude) !=
              (polygon[j].longitude > point.longitude) &&
          point.latitude <
              (polygon[j].latitude - polygon[i].latitude) *
                      (point.longitude - polygon[i].longitude) /
                      (polygon[j].longitude - polygon[i].longitude) +
                  polygon[i].latitude) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    for (final timer in _underAttackTimers.values) {
      timer.cancel();
    }
    _underAttackTimers.clear();
    _progressSyncTimer?.cancel();
    _positionSubscription?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(SupabaseService(), GameService(), ref);
});
