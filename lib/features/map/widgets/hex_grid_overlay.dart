import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/walk_models.dart';

enum TerritoryStatus { owned, protected, enemy, neutral }

class HexGridOverlay {
  HexGridOverlay._();

  static TerritoryStatus _getStatus(
    Territory territory,
    String? currentUserId,
  ) {
    if (territory.userId.isEmpty) return TerritoryStatus.neutral;
    if (territory.userId == currentUserId) {
      if (territory.hasShield()) return TerritoryStatus.protected;
      return territory.isProtected()
          ? TerritoryStatus.protected
          : TerritoryStatus.owned;
    }
    return territory.hasShield()
        ? TerritoryStatus.protected
        : TerritoryStatus.enemy;
  }

  /// Builds the full set of [Polygon] objects for the GoogleMap widget.
  /// Includes:
  ///   1. Visual H3-style hex grid background (decorative, like Uber)
  ///   2. Actual territory polygons drawn on top
  static Set<Polygon> build(
    List<Territory> territories,
    String? currentUserId, {
    LatLng? homeBase,
    LatLng? mapCenter,
    double zoomLevel = 15,
  }) {
    final Set<Polygon> polygons = {};

    // ── 1. Visual hex grid background ────────────────────────────────────────
    if (mapCenter != null) {
      polygons.addAll(
        H3GridTileOverlay.buildGrid(
          center: mapCenter,
          zoomLevel: zoomLevel,
          color: const Color(0xFF94A3B8),
          strokeColor: const Color(0xFF64748B),
          fillOpacity: 0.04, // very subtle — just outlines
        ),
      );
    }

    // ── 2. Territory polygons on top ─────────────────────────────────────────
    for (final territory in territories) {
      final polygon = _buildPolygon(
        territory,
        currentUserId,
        homeBase: homeBase,
      );
      if (polygon != null) polygons.add(polygon);
    }

    return polygons;
  }

  static Polygon? _buildPolygon(
    Territory territory,
    String? currentUserId, {
    LatLng? homeBase,
  }) {
    // Territory must have a polygon from the DB to be drawn
    if (!territory.hasPolygon) return null;

    final status = _getStatus(territory, currentUserId);

    Color fillColor;
    Color strokeColor;
    int strokeWidth;

    switch (status) {
      case TerritoryStatus.owned:
        fillColor = const Color(0xFF7B6FD4).withValues(alpha: 0.3);
        strokeColor = const Color(0xFF7B6FD4).withValues(alpha: 0.6);
        strokeWidth = 2;

      case TerritoryStatus.protected:
        fillColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        strokeColor = const Color(0xFF3B82F6).withValues(alpha: 0.6);
        strokeWidth = 2;

      case TerritoryStatus.enemy:
        fillColor = const Color(0xFFEF4444).withValues(alpha: 0.3);
        strokeColor = const Color(0xFFEF4444).withValues(alpha: 0.6);
        strokeWidth = 2;

      case TerritoryStatus.neutral:
        fillColor = const Color(0xFFF1F5F9).withValues(alpha: 0.1);
        strokeColor = const Color(0xFF94A3B8).withValues(alpha: 0.2);
        strokeWidth = 1;
    }

    // Home base gets a highlighted border
    final center = territory.center;
    final isHome =
        homeBase != null &&
        center != null &&
        (center.latitude - homeBase.latitude).abs() < 0.0001 &&
        (center.longitude - homeBase.longitude).abs() < 0.0001;

    if (isHome) {
      strokeColor = Colors.white;
      strokeWidth = 4;
    }

    return Polygon(
      polygonId: PolygonId('territory_${territory.id}'),
      points: territory.polygonPoints,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      consumeTapEvents: false,
    );
  }
}

// =============================================================================
// Pure visual H3-style hex grid — no territory logic, decorative only
// =============================================================================

class H3GridTileOverlay {
  H3GridTileOverlay._();

  static Set<Polygon> buildGrid({
    required LatLng center,
    required double zoomLevel,
    Color color = const Color(0xFF00BCD4),
    Color strokeColor = const Color(0xFF00ACC1),
    double fillOpacity = 0.04,
  }) {
    final double hexSizeDeg = _hexSizeForZoom(zoomLevel);
    final int rings = _ringsForZoom(zoomLevel);

    final Set<Polygon> polygons = {};
    final Set<String> seen = {};

    for (int q = -rings; q <= rings; q++) {
      for (int r = -rings; r <= rings; r++) {
        final int s = -q - r;
        if (s.abs() > rings) continue;

        final tileCenter = _axialToLatLng(center, q, r, hexSizeDeg);

        final key =
            '${(tileCenter.latitude * 1000).round()}_${(tileCenter.longitude * 1000).round()}';
        if (seen.contains(key)) continue;
        seen.add(key);

        final corners = _hexCorners(tileCenter, hexSizeDeg);

        polygons.add(
          Polygon(
            polygonId: PolygonId('hextile_${q}_$r'),
            points: corners,
            fillColor: color.withValues(alpha: fillOpacity),
            strokeColor: strokeColor.withValues(alpha: 0.30),
            strokeWidth: 1,
            consumeTapEvents: false,
          ),
        );
      }
    }

    return polygons;
  }

  static List<LatLng> _hexCorners(LatLng center, double sizeDeg) {
    return List.generate(6, (i) {
      final angle = math.pi / 180 * (60 * i);
      final lat = center.latitude + sizeDeg * math.sin(angle);
      final lngScale = math.cos(center.latitude * math.pi / 180);
      final lng =
          center.longitude +
          (sizeDeg / (lngScale > 0.01 ? lngScale : 0.01)) * math.cos(angle);
      return LatLng(lat, lng);
    });
  }

  static LatLng _axialToLatLng(LatLng origin, int q, int r, double sizeDeg) {
    final lngScale = math.cos(origin.latitude * math.pi / 180);
    final dx = sizeDeg * 1.5 * q;
    final dy = sizeDeg * math.sqrt(3) * (r + q / 2.0);
    return LatLng(
      origin.latitude + dy,
      origin.longitude + dx / (lngScale > 0.01 ? lngScale : 0.01),
    );
  }

  static double _hexSizeForZoom(double zoom) {
    return 0.0008 * math.pow(2, 15 - zoom.clamp(10, 20));
  }

  static int _ringsForZoom(double zoom) {
    if (zoom >= 17) return 8;
    if (zoom >= 15) return 6;
    if (zoom >= 13) return 5;
    if (zoom >= 11) return 4;
    return 3;
  }
}

// =============================================================================
// Tile Info Bottom Sheet — unchanged from original
// =============================================================================

