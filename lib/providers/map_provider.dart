import 'dart:async';
import 'dart:math' as math;

import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/map_model.dart';
import '../models/walk_models.dart';
 import '../services/supabase_service.dart';
import '../services/badge_service.dart';
import '../services/notification_service.dart';
import '../features/map/widgets/tile_handler.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class MapNotifier extends StateNotifier<MapState> {
  final SupabaseService _service;
  final BadgeService _badgeService;
  final MapTileHandler _tileHandler = MapTileHandler();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _liveLocationSubscription;
  List<String> _friendIds = [];

  supabase.User? get currentUser => _service.currentUser;

  MapNotifier(this._service, this._badgeService) : super(MapState()) {
    initialize();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    // Check location service
    if (!await Geolocator.isLocationServiceEnabled()) {
      state = state.copyWith(
        isLoading: false,
        error: 'Location services are disabled.',
      );
      return;
    }

    // Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        isLoading: false,
        error: 'Location permission denied.',
      );
      return;
    }

    state = state.copyWith(permissionGranted: true);

    final position = await Geolocator.getCurrentPosition();
    state = state.copyWith(
      userLocation: LatLng(position.latitude, position.longitude),
    );

    await _startLiveLocationTracking();
    state = state.copyWith(isLoading: false);
  }

  // ---------------------------------------------------------------------------
  // Live location tracking (friends only)
  // ---------------------------------------------------------------------------

  Future<void> _startLiveLocationTracking() async {
    _friendIds = await _service.getAcceptedInviteUserIds();
    if (_friendIds.isEmpty) return;

    _liveLocationSubscription?.cancel();
    _liveLocationSubscription = _service.getLocationStream().listen((points) {
      if (points.isEmpty) return;

      final updated = Map<String, LatLng>.from(state.liveUserLocations);
      bool changed = false;

      for (final point in points) {
        final uid = point['user_id']?.toString();
        if (uid == null || uid == currentUser?.id || !_friendIds.contains(uid))
          continue;

        final lat = (point['latitude'] as num).toDouble();
        final lng = (point['longitude'] as num).toDouble();
        final loc = LatLng(lat, lng);

        if (updated[uid] != loc) {
          updated[uid] = loc;
          changed = true;
        }
      }

      if (changed) state = state.copyWith(liveUserLocations: updated);
    });
  }

  // ---------------------------------------------------------------------------
  // Territory loading
  // ---------------------------------------------------------------------------

  /// Called on camera idle — fetches territories visible in the current viewport.
  Future<void> loadTerritoriesForBounds(LatLngBounds bounds) async {
    try {
      final centerLat =
          (bounds.southwest.latitude + bounds.northeast.latitude) / 2;
      final centerLng =
          (bounds.southwest.longitude + bounds.northeast.longitude) / 2;
      final radius = _boundsRadiusMeters(bounds);

      final fresh = await _service.getNearbyTerritories(
        centerLat,
        centerLng,
        radius: radius,
      );

      // Merge: existing + fresh (fresh wins on conflict)
      final merged = <String, Territory>{
        for (final t in state.nearbyTerritories) t.id: t,
        for (final t in fresh) t.id: t,
      };

      state = state.copyWith(nearbyTerritories: merged.values.toList());

      // ── Hex Tiles ──────────────────────────────────────────────────────────
      final hexTiles = await _tileHandler.loadTilesForBounds(
        swLat: bounds.southwest.latitude,
        swLng: bounds.southwest.longitude,
        neLat: bounds.northeast.latitude,
        neLng: bounds.northeast.longitude,
      );
      state = state.copyWith(visibleTiles: hexTiles);
    } catch (e) {
      print('[Map] loadTerritoriesForBounds error: $e');
    }
  }

  void selectTile(String? tileId) {
    state = state.copyWith(selectedTileId: tileId);
  }

  Future<void> getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
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

  // ---------------------------------------------------------------------------
  // Walk session — START
  // ---------------------------------------------------------------------------

  /// Creates a walking_sessions row and begins streaming GPS points.
  /// Call from MapScreen "Start Walk" FAB.
  Future<void> startWalk() async {
    if (state.isWalking) return;

    state = state.copyWith(isLoading: true, error: null);

    final sessionId = await _service.startWalkingSession();
    if (sessionId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start walk session.',
      );
      return;
    }

    state = state.copyWith(
      isWalking: true,
      currentSessionId: sessionId,
      activePath: [],
      sequenceNum: 0,
      isLoading: false,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_handleLocationUpdate);
  }

  // ---------------------------------------------------------------------------
  // Walk session — location updates while walking
  // ---------------------------------------------------------------------------

  // Tracks last tile processed to avoid calling the RPC on every GPS tick
  String? _lastProcessedTileId;

  void _handleLocationUpdate(Position position) {
    if (!state.isWalking || state.currentSessionId == null) return;

    final latLng = LatLng(position.latitude, position.longitude);
    final newPath = List<LatLng>.from(state.activePath)..add(latLng);
    final newSequence = state.sequenceNum + 1;
    final speedKmh = position.speed * 3.6; // m/s → km/h

    state = state.copyWith(
      userLocation: latLng,
      activePath: newPath,
      sequenceNum: newSequence,
      currentSpeedKmh: speedKmh,
    );

    final user = _service.currentUser;
    if (user == null) return;

    // Record GPS point — complete_walking_session builds the
    // convex hull polygon from these when the walk ends.
    _service.recordLocationPoint(
      LocationPoint(
        sessionId: state.currentSessionId!,
        userId: user.id,
        recordedAt: DateTime.now(),
        sequenceNum: newSequence,
        latitude: position.latitude,
        longitude: position.longitude,
        speedMps: position.speed,
        accuracyM: position.accuracy,
      ),
    );

    _checkTerritoryStatus(latLng, user.id);
    _checkCrossingNotifications(latLng, user.id);

    // ── Tile attack: compute current H3 tile and call the attack RPC ──────
    // Only fires when speed is in valid walk range (2–15 km/h)
    if (speedKmh >= 2 && speedKmh <= 15) {
      final tileId = _latLngToTileId(position.latitude, position.longitude);
      // Only process each tile once per entry — not on every GPS tick
      if (tileId != _lastProcessedTileId) {
        _lastProcessedTileId = tileId;
        _processTileEntry(tileId, latLng, speedKmh);
      }
    }
  }

  /// Calls claimOrAttackTile and surfaces the result to the UI via
  /// the attackResult field in MapState.
  Future<void> _processTileEntry(
    String tileId,
    LatLng location,
    double speedKmh,
  ) async {
    final result = await _service.claimOrAttackTile(
      tileId: tileId,
      lat: location.latitude,
      lng: location.longitude,
    );

    await _handleAttackResult(result, location);
  }

  /// Centralised logic for handling attack/claim results, including
  /// state updates, notifications, and map refreshes.
  Future<void> _handleAttackResult(
    Map<String, dynamic> result,
    LatLng location,
  ) async {
    // Push result into state so the UI (MapView) can react with toasts/animations
    state = state.copyWith(lastAttackResult: result);

    final action = result['action'] as String?;
    if (action == null) return;

    // ── Notifications ────────────────────────────────────────────────────────
    if (action == 'captured') {
      // 1. Achievements
      await _badgeService.checkTerritoryAchievements();
      await _badgeService.checkRaidAchievements(1);

      // 2. Notify involved parties via FCM
      if (result['previous_owner_id'] != null) {
        final victimUsername =
            result['previous_owner_username'] as String? ?? 'A rival';
        final myName = result['username'] as String? ?? 'Someone';

        // Notify attacker (victory)
        await NotificationService.notifyRaidVictory(currentUser!.id, victimUsername);
        // Notify defender (lost)
        await NotificationService.notifyTerritoryLost(
          result['previous_owner_id'],
          myName,
        );
      }

      // First time claim notification
      if (state.activePath.length <= 1) {
        await NotificationService.notifyFirstTerritoryClaim();
      }

      // 3. Map Refresh: reload territories so polygons update
      await loadTerritoriesForBounds(
        LatLngBounds(
          southwest: LatLng(location.latitude - 0.05, location.longitude - 0.05),
          northeast: LatLng(location.latitude + 0.05, location.longitude + 0.05),
        ),
      );
    } else if (action == 'damaged') {
      // Notify defender they are being attacked
      final defenderId = result['defender_id']?.toString();
      if (defenderId != null && defenderId.isNotEmpty) {
        await NotificationService.notifyTerritoryUnderAttack(defenderId);
      }
    }
  }

  /// Converts a GPS coordinate to an H3-style tile ID string.
  /// Uses a simple grid quantisation at ~60m resolution.
  /// Replace with the h3_flutter package for production accuracy.
  String _latLngToTileId(double lat, double lng) {
    // 0.0005 degrees ≈ 55m at equator — matches the 60m tile spec
    const double resolution = 0.0005;
    final int latGrid = (lat / resolution).floor();
    final int lngGrid = (lng / resolution).floor();
    return '${latGrid}_$lngGrid';
  }

  // ---------------------------------------------------------------------------
  // Walk session — STOP
  // ---------------------------------------------------------------------------

  /// Stops GPS stream, calls end_walking_session RPC (merges hull),
  /// then reloads territories on the map.
  /// Call from MapScreen "Stop Walk" FAB.
  Future<void> stopWalk() async {
    if (!state.isWalking || state.currentSessionId == null) return;

    state = state.copyWith(isLoading: true);

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // end_walking_session is an alias for complete_walking_session on the DB.
    // It merges the new convex hull into the territories table.
    final result = await _service.endWalkingSession(state.currentSessionId!);

    state = state.copyWith(
      isWalking: false,
      currentSessionId: null,
      isLoading: false,
    );

    final success = result['success'] as bool? ?? false;

    if (success) {
      // Reload the map so the new/expanded territory polygon appears
      if (state.userLocation != null) {
        await loadTerritoriesForBounds(
          LatLngBounds(
            southwest: LatLng(
              state.userLocation!.latitude - 0.05,
              state.userLocation!.longitude - 0.05,
            ),
            northeast: LatLng(
              state.userLocation!.latitude + 0.05,
              state.userLocation!.longitude + 0.05,
            ),
          ),
        );
      }

      final areaKm2 = ((result['area_m2'] as num?)?.toDouble() ?? 0) / 1e6;

      Fluttertoast.showToast(
        msg: 'Territory updated! ${areaKm2.toStringAsFixed(3)} km²',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: result['error']?.toString() ?? 'Walk ended with an error.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        fontSize: 16.0,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tile attack — called from map hex-tile hit detection
  // ---------------------------------------------------------------------------

  /// Public method for UI to manually trigger a tile entry (e.g. tile tap).
  /// Automatically called from _handleLocationUpdate during walks.
  Future<Map<String, dynamic>?> onEnterTile(String tileId) async {
    final speedKmh = state.currentSpeedKmh;
    if (speedKmh < 2 || speedKmh > 15) return null;
    if (state.userLocation == null) return null;

    final result = await _service.claimOrAttackTile(
      tileId: tileId,
      lat: state.userLocation!.latitude,
      lng: state.userLocation!.longitude,
    );

    await _handleAttackResult(result, state.userLocation!);
    return result;
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
      print('[Shield] Failed to activate: $e');
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
      if (_isPointInPolygon(point, territory.polygonPoints)) {
        newInsideIds.add(territory.id);
        // Only notify on first entry — not on every GPS update
        if (!currentInsideIds.contains(territory.id)) {
          _sendCrossingNotification(territory);
        }
      }
    }

    state = state.copyWith(currentlyInsideTerritoryIds: newInsideIds);
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
      print('[Map] _sendCrossingNotification error: $e');
    }
  }

  void _checkTerritoryStatus(LatLng point, String userId) {
    final ownTerritories = state.nearbyTerritories
        .where((t) => t.userId == userId && t.hasPolygon)
        .toList();

    final isInside = ownTerritories.any(
      (t) => _isPointInPolygon(point, t.polygonPoints),
    );

    if (!isInside && ownTerritories.isNotEmpty) {
      // User is outside their own territory — new area will be merged on stopWalk
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

  /// Haversine-based half-diagonal of LatLngBounds → metres.
  double _boundsRadiusMeters(LatLngBounds bounds) {
    const double R = 6371000.0;
    final lat1 = bounds.southwest.latitude * math.pi / 180;
    final lat2 = bounds.northeast.latitude * math.pi / 180;
    final lng1 = bounds.southwest.longitude * math.pi / 180;
    final lng2 = bounds.northeast.longitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a)) / 2;
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _liveLocationSubscription?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(SupabaseService(), BadgeService());
});
