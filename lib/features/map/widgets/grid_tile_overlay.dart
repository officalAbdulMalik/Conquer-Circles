import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pure visual H3-style hex grid overlay for Google Maps.
/// No territory logic — just decorative tiles like Uber's map.
///
/// Usage:
///   Set<Polygon> hexPolygons = H3GridOverlay.buildGrid(
///     center: cameraPosition.target,
///     zoomLevel: cameraPosition.zoom,
///   );
///   // Pass hexPolygons to GoogleMap's polygons parameter.
class H3GridTileOverlay {
  H3GridTileOverlay._();

  /// Build a set of hex tile polygons centered around [center].
  ///
  /// [zoomLevel]  — current camera zoom (tiles scale with zoom)
  /// [color]      — fill color of tiles (default semi-transparent teal)
  /// [strokeColor]— border color (default slightly darker teal)
  /// [fillOpacity]— 0.0 – 1.0 (default 0.08 — very subtle like Uber)
  static Set<Polygon> buildGrid({
    required LatLng center,
    required double zoomLevel,
    Color color = const Color(0xFF00BCD4),
    Color strokeColor = const Color(0xFF00ACC1),
    double fillOpacity = 0.08,
  }) {
    // Tile size shrinks as zoom increases (more tiles visible when zoomed in)
    final double hexSizeDeg = _hexSizeForZoom(zoomLevel);

    // How many rings of hexagons to generate around center
    final int rings = _ringsForZoom(zoomLevel);

    final Set<Polygon> polygons = {};
    final Set<String> seen = {};

    // Generate axial grid coordinates (cube coordinates for hex grid)
    for (int q = -rings; q <= rings; q++) {
      for (int r = -rings; r <= rings; r++) {
        final int s = -q - r;
        if (s.abs() > rings) continue; // Keep it hexagonal, not square

        // Convert axial coords → lat/lng center of this tile
        final tileCenter = _axialToLatLng(center, q, r, hexSizeDeg);

        // Deduplicate (floating point can cause near-duplicates at edges)
        final key =
            '${(tileCenter.latitude * 1000).round()}_${(tileCenter.longitude * 1000).round()}';
        if (seen.contains(key)) continue;
        seen.add(key);

        final corners = _hexCorners(tileCenter, hexSizeDeg);

        polygons.add(
          Polygon(
            polygonId: PolygonId('hex_${q}_${r}'),
            points: corners,
            fillColor: color.withValues(alpha: fillOpacity),
            strokeColor: strokeColor.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        );
      }
    }

    return polygons;
  }

  // ---------------------------------------------------------------------------
  // Geometry helpers
  // ---------------------------------------------------------------------------

  /// Flat-top hexagon corners around [center] with given [sizeDeg].
  static List<LatLng> _hexCorners(LatLng center, double sizeDeg) {
    return List.generate(6, (i) {
      // Flat-top: angles at 0°, 60°, 120°, 180°, 240°, 300°
      final angle = math.pi / 180 * (60 * i);
      final lat = center.latitude + sizeDeg * math.sin(angle);
      // Compensate lng for lat distortion so hexes look regular on screen
      final lngScale = math.cos(center.latitude * math.pi / 180);
      final lng =
          center.longitude +
          (sizeDeg / (lngScale > 0.01 ? lngScale : 0.01)) * math.cos(angle);
      return LatLng(lat, lng);
    });
  }

  /// Convert axial hex grid coordinates to a real LatLng.
  static LatLng _axialToLatLng(LatLng origin, int q, int r, double sizeDeg) {
    // Flat-top hex layout spacing
    final lngScale = math.cos(origin.latitude * math.pi / 180);
    final dx = sizeDeg * 1.5 * q;
    final dy = sizeDeg * math.sqrt(3) * (r + q / 2.0);

    return LatLng(
      origin.latitude + dy,
      origin.longitude + dx / (lngScale > 0.01 ? lngScale : 0.01),
    );
  }

  /// Hex tile size in degrees, scaled to zoom level.
  /// At zoom 15 tiles are ~city-block sized; at zoom 12 they're larger.
  static double _hexSizeForZoom(double zoom) {
    // Base size at zoom 15 ≈ 0.0008° (~90m radius)
    // Doubles for every zoom level decrease
    return 0.0008 * math.pow(2, 15 - zoom.clamp(10, 20));
  }

  /// Number of hex rings to generate (fewer at low zoom to save performance).
  static int _ringsForZoom(double zoom) {
    if (zoom >= 17) return 8;
    if (zoom >= 15) return 6;
    if (zoom >= 13) return 5;
    if (zoom >= 11) return 4;
    return 3;
  }
}
