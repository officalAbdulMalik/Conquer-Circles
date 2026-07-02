import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/map_model.dart';

void main() {
  test('MapState tracks foreground location and speed', () {
    final state = MapState().copyWith(
      userLocation: const LatLng(31.5204, 74.3587),
      currentSpeedMps: 1.5,
      currentSpeedKmh: 5.4,
    );

    expect(state.userLocation, const LatLng(31.5204, 74.3587));
    expect(state.currentSpeedMps, 1.5);
    expect(state.currentSpeedKmh, 5.4);
  });
}
