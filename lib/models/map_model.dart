import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/walk_models.dart';

class MapState {
  final LatLng? userLocation;
  final bool isLoading;
  final String? error;
  final bool permissionGranted;

  // Walking Session State
  final bool isWalking;
  final String? currentSessionId;
  final List<LatLng> activePath;
  final List<Territory> nearbyTerritories;
  final int sequenceNum;
  final Set<String> currentlyInsideTerritoryIds;
  final Map<String, LatLng> liveUserLocations;
  final double currentSpeedKmh;
  final Map<String, dynamic>? lastAttackResult;

  // Hex Tile Territory System
  final LatLng? homeBase;

  // Current GPS speed in m/s — updated every position event while walking.
  final double? currentSpeedMps;

  MapState({
    this.userLocation,
    this.isLoading = false,
    this.error,
    this.permissionGranted = false,
    this.isWalking = false,
    this.currentSessionId,
    this.activePath = const [],
    this.nearbyTerritories = const [],
    this.sequenceNum = 0,
    this.currentlyInsideTerritoryIds = const {},
    this.liveUserLocations = const {},
    this.homeBase,
    this.currentSpeedKmh = 0.0,
    this.lastAttackResult,
    this.currentSpeedMps,
  });

  MapState copyWith({
    LatLng? userLocation,
    bool? isLoading,
    String? error,
    bool? permissionGranted,
    bool? isWalking,
    String? currentSessionId,
    List<LatLng>? activePath,
    List<Territory>? nearbyTerritories,
    int? sequenceNum,
    Set<String>? currentlyInsideTerritoryIds,
    Map<String, LatLng>? liveUserLocations,
    LatLng? homeBase,
    bool clearHomeBase = false,
    double? currentSpeedMps,
    bool clearSpeed = false,
    double? currentSpeedKmh,
    Map<String, dynamic>? lastAttackResult,
  }) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isWalking: isWalking ?? this.isWalking,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      activePath: activePath ?? this.activePath,
      nearbyTerritories: nearbyTerritories ?? this.nearbyTerritories,
      sequenceNum: sequenceNum ?? this.sequenceNum,
      currentlyInsideTerritoryIds:
          currentlyInsideTerritoryIds ?? this.currentlyInsideTerritoryIds,
      liveUserLocations: liveUserLocations ?? this.liveUserLocations,
      homeBase: clearHomeBase ? null : (homeBase ?? this.homeBase),
      currentSpeedMps: clearSpeed
          ? null
          : (currentSpeedMps ?? this.currentSpeedMps),
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      lastAttackResult: lastAttackResult ?? this.lastAttackResult,
    );
  }
}
