import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/models/map_model.dart';
import 'package:test_steps/models/walk_models.dart';

class SimulatedWalkPoint {
  const SimulatedWalkPoint({required this.location, required this.speedKmh});

  final LatLng location;
  final double speedKmh;
}

class SimulatedPlayerActivity {
  const SimulatedPlayerActivity({
    required this.stepsToday,
    this.isPremium = false,
  });

  final int stepsToday;
  final bool isPremium;

  int get attackEnergy {
    final cap = isPremium ? 600 : 400;
    return math.min(cap, stepsToday ~/ 100);
  }
}

class SimulatedTerritoryContext {
  const SimulatedTerritoryContext({
    this.clusterSize = 0,
    this.homeBase,
    this.now,
    this.recentlyActiveOwnerIds = const {},
  });

  final int clusterSize;
  final LatLng? homeBase;
  final DateTime? now;
  final Set<String> recentlyActiveOwnerIds;
}

class SimulatedTerritoryAction {
  const SimulatedTerritoryAction({
    required this.territoryId,
    required this.action,
    this.energyUsed = 0,
    this.energyBefore,
    this.energyAfter,
  });

  final String territoryId;
  final String action;
  final int energyUsed;
  final int? energyBefore;
  final int? energyAfter;
}

class SimulatedWalkResult {
  const SimulatedWalkResult({
    required this.state,
    required this.history,
    required this.actions,
  });

  final MapState state;
  final List<TerritoryHistoryEntry> history;
  final List<SimulatedTerritoryAction> actions;
}

class MapWalkSimulator {
  MapWalkSimulator({
    required this.currentUserId,
    required this.territories,
    this.initialEnergy = 60,
    this.context = const SimulatedTerritoryContext(),
  });

  final String currentUserId;
  final List<Territory> territories;
  final int initialEnergy;
  final SimulatedTerritoryContext context;

  SimulatedWalkResult run(List<SimulatedWalkPoint> route) {
    var state = MapState().copyWith(
      isRunActive: true,
      currentAttackEnergy: initialEnergy,
      nearbyTerritories: territories,
    );
    final actions = <SimulatedTerritoryAction>[];
    final visitedTerritoryIds = <String>{};

    for (final point in route) {
      state = state.copyWith(
        userLocation: point.location,
        currentSpeedKmh: point.speedKmh,
        currentSpeedMps: point.speedKmh / 3.6,
        runRoute: [...state.runRoute, point.location],
      );

      if (point.speedKmh < 2 || point.speedKmh > 15) {
        continue;
      }

      final territory = _territoryAt(point.location);
      if (territory == null || visitedTerritoryIds.contains(territory.id)) {
        continue;
      }

      visitedTerritoryIds.add(territory.id);
      final action = _resolveAction(territory, state.currentAttackEnergy);
      if (action == null) {
        continue;
      }

      actions.add(action);
      if (action.action == 'claimed' || action.action == 'captured') {
        state = state.copyWith(
          runClaimedTerritoryIds: {
            ...state.runClaimedTerritoryIds,
            action.territoryId,
          },
          runClaimedAreaKm2:
              state.runClaimedAreaKm2 +
              _polygonAreaKm2(territory.polygonPoints),
        );
      }
      state = state.copyWith(
        currentAttackEnergy: math.max(
          0,
          state.currentAttackEnergy - action.energyUsed,
        ),
        lastAttackResult: {
          'action': action.action,
          'territory_id': action.territoryId,
          'energy_used': action.energyUsed,
          'territory_energy_before': action.energyBefore,
          'territory_energy_after': action.energyAfter,
        },
      );
    }

    state = state.copyWith(isRunActive: false, isRunPaused: false);
    return SimulatedWalkResult(
      state: state,
      history: _historyFromActions(actions),
      actions: actions,
    );
  }

  Territory? _territoryAt(LatLng point) {
    for (final territory in territories) {
      if (territory.hasPolygon &&
          _isPointInPolygon(point, territory.polygonPoints)) {
        return territory;
      }
    }
    return null;
  }

  SimulatedTerritoryAction? _resolveAction(Territory territory, int energy) {
    final now = context.now ?? DateTime.now();
    if (_isProtected(territory, now) ||
        territory.cooldownUntil?.isAfter(now) == true) {
      return SimulatedTerritoryAction(
        territoryId: territory.id,
        action: _isProtected(territory, now) ? 'protected' : 'cooldown',
      );
    }

    if (energy <= 0) {
      return SimulatedTerritoryAction(
        territoryId: territory.id,
        action: 'no_energy',
      );
    }

    final energyUsed = math.min(energy, territory.userId.isEmpty ? 20 : energy);
    if (territory.userId.isEmpty) {
      return SimulatedTerritoryAction(
        territoryId: territory.id,
        action: 'claimed',
        energyUsed: energyUsed,
        energyBefore: 0,
        energyAfter: calculateTileEnergy(
          territory: territory,
          energyUsed: energyUsed,
          context: context,
        ),
      );
    }

    if (territory.userId == currentUserId) {
      final energyUsed = math.min(20, energy);
      return SimulatedTerritoryAction(
        territoryId: territory.id,
        action: 'reinforced',
        energyUsed: energyUsed,
        energyBefore: territory.energy,
        energyAfter: calculateTileEnergy(
          territory: territory,
          energyUsed: energyUsed,
          context: context,
          existingEnergy: territory.energy,
        ),
      );
    }

    final absenceShieldActive = context.recentlyActiveOwnerIds.contains(
      territory.userId,
    );
    final captured = energy >= territory.energy && !absenceShieldActive;
    final reducedEnergy = math.max(
      absenceShieldActive ? 20 : 0,
      territory.energy - energy,
    );
    return SimulatedTerritoryAction(
      territoryId: territory.id,
      action: captured ? 'captured' : 'damaged',
      energyUsed: energy,
      energyBefore: territory.energy,
      energyAfter: captured ? 10 : reducedEnergy,
    );
  }

  bool _isProtected(Territory territory, DateTime now) {
    return territory.protectedUntil?.isAfter(now) == true ||
        territory.shieldUntil?.isAfter(now) == true;
  }

  List<TerritoryHistoryEntry> _historyFromActions(
    List<SimulatedTerritoryAction> actions,
  ) {
    return actions
        .where(
          (action) =>
              action.action == 'claimed' ||
              action.action == 'captured' ||
              action.action == 'damaged' ||
              action.action == 'reinforced',
        )
        .map(
          (action) => TerritoryHistoryEntry.fromJson({
            'id': 'sim_${action.territoryId}_${action.action}',
            'territory_id': action.territoryId,
            'action': action.action,
            'energy_used': action.energyUsed,
            'energy_before': action.energyBefore,
            'energy_after': action.energyAfter,
            'captured': action.action == 'captured',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_defence': false,
          }),
        )
        .toList();
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    var inside = false;
    var j = polygon.length - 1;
    for (var i = 0; i < polygon.length; i++) {
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

  double _polygonAreaKm2(List<LatLng> points) {
    if (points.length < 3) return 0;
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
}

int calculateTileEnergy({
  required Territory territory,
  required int energyUsed,
  required SimulatedTerritoryContext context,
  int? existingEnergy,
}) {
  final now = context.now ?? DateTime.now();
  final baseEnergy = existingEnergy ?? 10;
  final sameDayRevisitBonus = _isSameDay(territory.lastActivityTime, now)
      ? 5
      : 0;
  final holdBonus =
      territory.captureTime != null &&
          !territory.captureTime!.isAfter(
            now.subtract(const Duration(hours: 48)),
          )
      ? 10
      : 0;
  final clusterBonus = clusterDefenseBonus(context.clusterSize);
  final homeBonus = _isNearHomeBase(territory, context.homeBase) ? 10 : 0;

  return math.min(
    60,
    baseEnergy +
        energyUsed +
        sameDayRevisitBonus +
        holdBonus +
        clusterBonus +
        homeBonus,
  );
}

int clusterDefenseBonus(int connectedTileCount) {
  if (connectedTileCount >= 15) return 20;
  if (connectedTileCount >= 7) return 10;
  if (connectedTileCount >= 3) return 5;
  return 0;
}

Territory decayTerritory(Territory territory, DateTime now) {
  final lastVisit = territory.lastActivityTime ?? territory.captureTime;
  if (lastVisit == null) return territory;

  final inactiveDays = now.difference(lastVisit).inDays;
  if (inactiveDays <= 3) return territory;

  final decayDays = inactiveDays - 3;
  final energyAfterDecay = math.max(0, territory.energy - decayDays * 2);
  return territory.copyWith(
    energy: energyAfterDecay,
    userId: energyAfterDecay == 0 ? '' : territory.userId,
    username: energyAfterDecay == 0 ? 'Unclaimed' : territory.username,
  );
}

bool _isSameDay(DateTime? value, DateTime now) {
  if (value == null) return false;
  final local = value.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

bool _isNearHomeBase(Territory territory, LatLng? homeBase) {
  final center = territory.center;
  if (homeBase == null || center == null) return false;
  return _distanceMeters(center, homeBase) <= 150;
}

double _distanceMeters(LatLng a, LatLng b) {
  const earthRadiusMeters = 6371008.8;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadiusMeters * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

List<LatLng> squareAround(double lat, double lng, {double delta = 0.001}) {
  return [
    LatLng(lat - delta, lng - delta),
    LatLng(lat - delta, lng + delta),
    LatLng(lat + delta, lng + delta),
    LatLng(lat + delta, lng - delta),
  ];
}
