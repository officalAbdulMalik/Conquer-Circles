import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/walk_models.dart';

import 'helpers/map_walk_simulator.dart';

void main() {
  const userId = 'user-1';
  final now = DateTime(2026, 6, 16, 12);

  test('too slow speed blocks phone-shaking style territory actions', () {
    final simulator = MapWalkSimulator(
      currentUserId: userId,
      territories: [
        Territory(
          id: 'neutral-1',
          userId: '',
          username: 'Unclaimed',
          color: '#cccccc',
          polygonPoints: squareAround(31.5204, 74.3587),
        ),
      ],
    );

    final result = simulator.run([
      const SimulatedWalkPoint(
        location: LatLng(31.5204, 74.3587),
        speedKmh: 1.5,
      ),
    ]);

    expect(result.actions, isEmpty);
    expect(result.history, isEmpty);
  });

  test(
    'attack energy converts from steps with free and premium daily caps',
    () {
      expect(const SimulatedPlayerActivity(stepsToday: 9900).attackEnergy, 99);
      expect(
        const SimulatedPlayerActivity(stepsToday: 50000).attackEnergy,
        400,
      );
      expect(
        const SimulatedPlayerActivity(
          stepsToday: 70000,
          isPremium: true,
        ).attackEnergy,
        600,
      );
    },
  );

  test('same-day revisit adds 5 energy and caps at 60', () {
    final energy = calculateTileEnergy(
      territory: Territory(
        id: 'own-1',
        userId: userId,
        username: 'Me',
        color: '#0000ff',
        energy: 57,
        lastActivityTime: now.subtract(const Duration(hours: 2)),
        polygonPoints: squareAround(31.5204, 74.3587),
      ),
      energyUsed: 10,
      existingEnergy: 57,
      context: SimulatedTerritoryContext(now: now),
    );

    expect(energy, 60);
  });

  test('holding territory for 48 hours adds 10 defense energy', () {
    final energy = calculateTileEnergy(
      territory: Territory(
        id: 'own-1',
        userId: userId,
        username: 'Me',
        color: '#0000ff',
        energy: 20,
        captureTime: now.subtract(const Duration(hours: 49)),
        polygonPoints: squareAround(31.5204, 74.3587),
      ),
      energyUsed: 0,
      existingEnergy: 20,
      context: SimulatedTerritoryContext(now: now),
    );

    expect(energy, 30);
  });

  test('home base proximity adds 10 defense energy', () {
    final energy = calculateTileEnergy(
      territory: Territory(
        id: 'own-1',
        userId: userId,
        username: 'Me',
        color: '#0000ff',
        energy: 20,
        center: const LatLng(31.5204, 74.3587),
        polygonPoints: squareAround(31.5204, 74.3587),
      ),
      energyUsed: 0,
      existingEnergy: 20,
      context: const SimulatedTerritoryContext(
        homeBase: LatLng(31.5205, 74.3588),
      ),
    );

    expect(energy, 30);
  });

  test('cluster thresholds add 5, 10, and 20 defense energy', () {
    expect(clusterDefenseBonus(2), 0);
    expect(clusterDefenseBonus(3), 5);
    expect(clusterDefenseBonus(7), 10);
    expect(clusterDefenseBonus(15), 20);
  });

  test('cluster bonus is included in tile energy calculation', () {
    final energy = calculateTileEnergy(
      territory: Territory(
        id: 'own-1',
        userId: userId,
        username: 'Me',
        color: '#0000ff',
        energy: 20,
        polygonPoints: squareAround(31.5204, 74.3587),
      ),
      energyUsed: 0,
      existingEnergy: 20,
      context: const SimulatedTerritoryContext(clusterSize: 7),
    );

    expect(energy, 30);
  });

  test('territory decays 2 energy per day after 3 inactive days', () {
    final territory = Territory(
      id: 'own-1',
      userId: userId,
      username: 'Me',
      color: '#0000ff',
      energy: 30,
      lastActivityTime: now.subtract(const Duration(days: 6)),
    );

    final decayed = decayTerritory(territory, now);

    expect(decayed.energy, 24);
    expect(decayed.userId, userId);
  });

  test('territory becomes neutral when decay reaches zero energy', () {
    final territory = Territory(
      id: 'own-1',
      userId: userId,
      username: 'Me',
      color: '#0000ff',
      energy: 4,
      lastActivityTime: now.subtract(const Duration(days: 6)),
    );

    final decayed = decayTerritory(territory, now);

    expect(decayed.energy, 0);
    expect(decayed.userId, isEmpty);
    expect(decayed.username, 'Unclaimed');
  });

  test(
    'recently active owner absence shield keeps enemy tile at 20 energy',
    () {
      final simulator = MapWalkSimulator(
        currentUserId: userId,
        initialEnergy: 80,
        context: const SimulatedTerritoryContext(
          recentlyActiveOwnerIds: {'enemy-1'},
        ),
        territories: [
          Territory(
            id: 'enemy-tile',
            userId: 'enemy-1',
            username: 'Enemy',
            color: '#ff0000',
            energy: 40,
            polygonPoints: squareAround(31.5204, 74.3587),
          ),
        ],
      );

      final result = simulator.run([
        const SimulatedWalkPoint(
          location: LatLng(31.5204, 74.3587),
          speedKmh: 5,
        ),
      ]);

      expect(result.actions.single.action, 'damaged');
      expect(result.actions.single.energyAfter, 20);
      expect(result.history.single.action, 'damaged');
    },
  );

  test('cooldown blocks repeat attack spam', () {
    final simulator = MapWalkSimulator(
      currentUserId: userId,
      initialEnergy: 80,
      context: SimulatedTerritoryContext(now: now),
      territories: [
        Territory(
          id: 'enemy-tile',
          userId: 'enemy-1',
          username: 'Enemy',
          color: '#ff0000',
          energy: 40,
          cooldownUntil: now.add(const Duration(minutes: 30)),
          polygonPoints: squareAround(31.5204, 74.3587),
        ),
      ],
    );

    final result = simulator.run([
      const SimulatedWalkPoint(location: LatLng(31.5204, 74.3587), speedKmh: 5),
    ]);

    expect(result.actions.single.action, 'cooldown');
    expect(result.history, isEmpty);
  });
}
