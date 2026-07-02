import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/walk_models.dart';

import 'helpers/map_walk_simulator.dart';

void main() {
  const userId = 'user-1';

  test('walking through neutral territory claims it and creates history', () {
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
      initialEnergy: 40,
    );

    final result = simulator.run([
      const SimulatedWalkPoint(location: LatLng(31.5204, 74.3587), speedKmh: 5),
    ]);

    expect(result.actions.single.action, 'claimed');
    expect(result.state.runClaimedTerritoryIds, contains('neutral-1'));
    expect(result.state.runClaimedAreaKm2, greaterThan(0));
    expect(result.history.single.action, 'claimed');
  });

  test('invalid walking speed does not trigger territory action', () {
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
        speedKmh: 22,
      ),
    ]);

    expect(result.actions, isEmpty);
    expect(result.history, isEmpty);
    expect(result.state.runClaimedTerritoryIds, isEmpty);
  });

  test('walking through enemy territory captures when energy is enough', () {
    final simulator = MapWalkSimulator(
      currentUserId: userId,
      territories: [
        Territory(
          id: 'enemy-1',
          userId: 'enemy-1',
          username: 'Enemy',
          color: '#ff0000',
          energy: 20,
          polygonPoints: squareAround(31.5204, 74.3587),
        ),
      ],
      initialEnergy: 25,
    );

    final result = simulator.run([
      const SimulatedWalkPoint(location: LatLng(31.5204, 74.3587), speedKmh: 5),
    ]);

    expect(result.actions.single.action, 'captured');
    expect(result.history.single.action, 'captured');
    expect(result.state.currentAttackEnergy, 0);
  });

  test('walking through enemy territory damages when energy is not enough', () {
    final simulator = MapWalkSimulator(
      currentUserId: userId,
      territories: [
        Territory(
          id: 'enemy-1',
          userId: 'enemy-1',
          username: 'Enemy',
          color: '#ff0000',
          energy: 40,
          polygonPoints: squareAround(31.5204, 74.3587),
        ),
      ],
      initialEnergy: 15,
    );

    final result = simulator.run([
      const SimulatedWalkPoint(location: LatLng(31.5204, 74.3587), speedKmh: 5),
    ]);

    expect(result.actions.single.action, 'damaged');
    expect(result.history.single.action, 'damaged');
    expect(result.actions.single.energyAfter, 25);
  });

  test('protected territory blocks history-changing actions', () {
    final simulator = MapWalkSimulator(
      currentUserId: userId,
      territories: [
        Territory(
          id: 'enemy-1',
          userId: 'enemy-1',
          username: 'Enemy',
          color: '#ff0000',
          energy: 20,
          protectedUntil: DateTime.now().add(const Duration(hours: 1)),
          polygonPoints: squareAround(31.5204, 74.3587),
        ),
      ],
      initialEnergy: 40,
    );

    final result = simulator.run([
      const SimulatedWalkPoint(location: LatLng(31.5204, 74.3587), speedKmh: 5),
    ]);

    expect(result.actions.single.action, 'protected');
    expect(result.history, isEmpty);
  });
}
