import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/models/map_model.dart';
import 'package:test_steps/models/walk_models.dart';

void main() {
  test('MapState preserves live run metrics through copyWith', () {
    final state = MapState().copyWith(
      isRunActive: true,
      runRoute: const [LatLng(31.5, 74.3), LatLng(31.5001, 74.3001)],
      runDistanceKm: 1.25,
      runSteps: 1450,
      runClaimedAreaKm2: 0.04,
      runClaimedTerritoryIds: const {'territory-1'},
    );

    expect(state.isRunActive, isTrue);
    expect(state.runRoute, hasLength(2));
    expect(state.runDistanceKm, 1.25);
    expect(state.runSteps, 1450);
    expect(state.runClaimedAreaKm2, 0.04);
    expect(state.runClaimedTerritoryIds, contains('territory-1'));
  });

  test('Territory reports active protection and shield windows', () {
    final territory = Territory(
      id: 'territory-1',
      userId: 'owner-1',
      username: 'Owner',
      color: '#000000',
      protectedUntil: DateTime.now().add(const Duration(hours: 1)),
      shieldUntil: DateTime.now().add(const Duration(hours: 2)),
    );

    expect(territory.isProtected(), isTrue);
    expect(territory.hasShield(), isTrue);
  });

  test('Territory history keeps the server action for neutral claims', () {
    final entry = TerritoryHistoryEntry.fromJson({
      'id': 'log-1',
      'territory_id': 'territory-1',
      'action': 'claimed',
      'energy_used': 10,
      'energy_before': 0,
      'energy_after': 20,
      'captured': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    expect(entry.action, 'claimed');
  });

  test('Territory parses live get_territories_nearby RPC shape', () {
    final territory = Territory.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'user_id': 'a0000001-0000-0000-0000-000000000001',
      'username': 'sim_attacker',
      'color': '#9E9E9E',
      'energy': 40,
      'polygon_points': [
        {'lat': 37.77455, 'lng': -122.4201},
        {'lat': 37.77495, 'lng': -122.4201},
        {'lat': 37.77495, 'lng': -122.4197},
        {'lat': 37.77455, 'lng': -122.4197},
        {'lat': 37.77455, 'lng': -122.4201},
      ],
      'centroid': {'lat': 37.77475, 'lng': -122.4199},
      'capture_time': '2026-06-19T10:23:45.522326+00:00',
      'last_activity_time': '2026-06-19T10:23:45.522326+00:00',
      'protected_until': '2026-06-19T22:23:45.522326+00:00',
      'shield_until': '2026-06-20T10:23:45.522326+00:00',
      'cooldown_until': null,
    });

    expect(territory.id, '11111111-1111-1111-1111-111111111111');
    expect(territory.userId, 'a0000001-0000-0000-0000-000000000001');
    expect(territory.username, 'sim_attacker');
    expect(territory.energy, 40);
    expect(territory.polygonPoints, hasLength(5));
    expect(territory.hasPolygon, isTrue);
    expect(territory.center, isNotNull);
    expect(territory.center!.latitude, closeTo(37.77475, 0.000001));
    expect(territory.center!.longitude, closeTo(-122.4199, 0.000001));
    expect(territory.protectedUntil, isNotNull);
    expect(territory.shieldUntil, isNotNull);
  });
}
