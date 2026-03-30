import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:h3_flutter/h3_flutter.dart';
import 'dart:math';

class H3Utils {
  // Initialize the FFI instance once
  static final H3 _h3 = const H3Factory().load();

  // Resolution 10 provides hexagons with an edge length of ~66m
  // and an area of ~1.1 hectare, perfect for walking territories.
  static const int claimResolution = 10;

  /// Converts a GPS location to the Uber H3 string index
  static String latLngToH3(LatLng location) {
    final cell = _h3.geoToCell(
      GeoCoord(lat: location.latitude, lon: location.longitude),
      claimResolution,
    );
    return cell.toRadixString(16);
  }

  /// Gets the center LatLng for a given H3 string index
  static LatLng? h3ToLatLng(String h3Index) {
    try {
      final cell = BigInt.parse(h3Index, radix: 16);
      final coord = _h3.cellToGeo(cell);
      return LatLng(coord.lat, coord.lon);
    } catch (e) {
      print('Error parsing H3 index for center: $h3Index');
      return null;
    }
  }

  /// Gets the 6 boundary corners for drawing the hexagon polygon on Google Maps
  // static List<LatLng> h3Corners(String h3Index) {
  //   try {
  //     final cell = BigInt.parse(h3Index, radix: 16);
  //     final boundary = _h3.cellToBoundary(cell);
  //     return boundary.map((coord) => LatLng(coord.lat, coord.lon)).toList();
  //   } catch (e) {
  //     print('Error parsing H3 index for corners: $h3Index');
  //     return [];
  //   }
  // }

  /// Gets neighboring H3 indices (e.g. 1 ring out = 6 neighbors)
  static List<String> h3Neighbors(String h3Index, {int distance = 1}) {
    try {
      final cell = BigInt.parse(h3Index, radix: 16);
      final cells = _h3.gridDisk(cell, distance);
      return cells
          .map((c) => c.toRadixString(16))
          .where((id) => id != h3Index)
          .toList();
    } catch (e) {
      print('Error parsing H3 index for neighbors: $h3Index');
      return [];
    }
  }

  /// Calculate distance between two lat/lng points in meters
  static double distanceMeters(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000;
    final dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final dLon = _degreesToRadians(p2.longitude - p1.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(p1.latitude)) *
            cos(_degreesToRadians(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Converts meters per second to kilometers per hour
  static double mpsToKmh(double speedMps) {
    return speedMps * 3.6;
  }

  /// Checks if the speed is within the valid walking range (2 - 15 km/h)
  static bool isValidWalkingSpeed(double speedMps) {
    final speedKmh = mpsToKmh(speedMps);
    return speedKmh >= 2.0 && speedKmh <= 15.0;
  }

  /// Get all H3 cells of [claimResolution] within the given [bounds]
  static List<String> getCellsInBounds(LatLngBounds bounds) {
    try {
      final perimeter = [
        GeoCoord(
          lat: bounds.northeast.latitude,
          lon: bounds.northeast.longitude,
        ),
        GeoCoord(
          lat: bounds.northeast.latitude,
          lon: bounds.southwest.longitude,
        ),
        GeoCoord(
          lat: bounds.southwest.latitude,
          lon: bounds.southwest.longitude,
        ),
        GeoCoord(
          lat: bounds.southwest.latitude,
          lon: bounds.northeast.longitude,
        ),
      ];

      final cells = _h3.polygonToCells(
        perimeter: perimeter,
        resolution: claimResolution,
      );

      return cells.map((c) => c.toRadixString(16)).toList();
    } catch (e) {
      print('Error generating cells in bounds: $e');
      return [];
    }
  }
}
