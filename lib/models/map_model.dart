import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/walk_models.dart';

class MapState {
  final LatLng? userLocation;
  final bool isLoading;
  final String? error;
  final bool permissionGranted;

  final List<Territory> nearbyTerritories;
  final Set<String> currentlyInsideTerritoryIds;
  final double currentSpeedKmh;
  final Map<String, dynamic>? lastAttackResult;
  final int currentAttackEnergy; // Player's current attack energy (0-600)
  final LatLng? homeBase;
  final bool isRunActive;
  final bool isRunPaused;
  final List<LatLng> runRoute;
  // Faithful visual trail of the walk (distance-based, captures turnarounds).
  // Kept separate from [runRoute], which is speed-gated for anti-cheat/metrics.
  final List<LatLng> trailPoints;
  final double runDistanceKm;
  final int runSteps;
  final double runClaimedAreaKm2;
  final Set<String> runClaimedTerritoryIds;
  final Set<String> underAttackTerritoryIds;

  // Current GPS speed in m/s.
  final double? currentSpeedMps;

  /// Display anchor for the run timer. Shifted forward on resume so elapsed
  /// time excludes pauses — the UI just renders `now - runStartedAt`.
  final DateTime? runStartedAt;

  /// When the current pause began (null while running).
  final DateTime? runPausedAt;

  MapState({
    this.userLocation,
    this.isLoading = false,
    this.error,
    this.permissionGranted = false,
    this.nearbyTerritories = const [],
    this.currentlyInsideTerritoryIds = const {},
    this.homeBase,
    this.currentSpeedKmh = 0.0,
    this.currentAttackEnergy = 0,
    this.lastAttackResult,
    this.currentSpeedMps,
    this.isRunActive = false,
    this.isRunPaused = false,
    this.runRoute = const [],
    this.trailPoints = const [],
    this.runDistanceKm = 0,
    this.runSteps = 0,
    this.runClaimedAreaKm2 = 0,
    this.runClaimedTerritoryIds = const {},
    this.underAttackTerritoryIds = const {},
    this.runStartedAt,
    this.runPausedAt,
  });

  MapState copyWith({
    LatLng? userLocation,
    bool? isLoading,
    String? error,
    bool? permissionGranted,
    List<Territory>? nearbyTerritories,
    Set<String>? currentlyInsideTerritoryIds,
    LatLng? homeBase,
    bool clearHomeBase = false,
    double? currentSpeedMps,
    bool clearSpeed = false,
    double? currentSpeedKmh,
    int? currentAttackEnergy,
    Map<String, dynamic>? lastAttackResult,
    bool? isRunActive,
    bool? isRunPaused,
    List<LatLng>? runRoute,
    List<LatLng>? trailPoints,
    double? runDistanceKm,
    int? runSteps,
    double? runClaimedAreaKm2,
    Set<String>? runClaimedTerritoryIds,
    Set<String>? underAttackTerritoryIds,
    DateTime? runStartedAt,
    bool clearRunStartedAt = false,
    DateTime? runPausedAt,
    bool clearRunPausedAt = false,
  }) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      nearbyTerritories: nearbyTerritories ?? this.nearbyTerritories,
      currentlyInsideTerritoryIds:
          currentlyInsideTerritoryIds ?? this.currentlyInsideTerritoryIds,
      homeBase: clearHomeBase ? null : (homeBase ?? this.homeBase),
      currentSpeedMps: clearSpeed
          ? null
          : (currentSpeedMps ?? this.currentSpeedMps),
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentAttackEnergy: currentAttackEnergy ?? this.currentAttackEnergy,
      lastAttackResult: lastAttackResult ?? this.lastAttackResult,
      isRunActive: isRunActive ?? this.isRunActive,
      isRunPaused: isRunPaused ?? this.isRunPaused,
      runRoute: runRoute ?? this.runRoute,
      trailPoints: trailPoints ?? this.trailPoints,
      runDistanceKm: runDistanceKm ?? this.runDistanceKm,
      runSteps: runSteps ?? this.runSteps,
      runClaimedAreaKm2: runClaimedAreaKm2 ?? this.runClaimedAreaKm2,
      runClaimedTerritoryIds:
          runClaimedTerritoryIds ?? this.runClaimedTerritoryIds,
      underAttackTerritoryIds:
          underAttackTerritoryIds ?? this.underAttackTerritoryIds,
      runStartedAt: clearRunStartedAt
          ? null
          : (runStartedAt ?? this.runStartedAt),
      runPausedAt: clearRunPausedAt
          ? null
          : (runPausedAt ?? this.runPausedAt),
    );
  }
}
