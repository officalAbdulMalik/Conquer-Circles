import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class Territory {
  final String id; // DB row id (UUID) or user_id depending on your schema
  final String userId; // Owner
  final String username;
  final String color;
  final int energy;

  /// The polygon boundary returned by the get_territories_nearby RPC.
  /// Populated from the `polygon_points` JSON array: [{lat, lng}, ...]
  /// (exterior ring of the largest part). Empty list means no polygon has
  /// been saved yet for this territory.
  final List<LatLng> polygonPoints;

  /// Full ring/part structure parsed from the RPC's `geojson` field:
  /// parts → rings → points, where ring 0 of each part is the exterior
  /// boundary and any further rings are holes. A merged (dissolved) cluster
  /// is usually a single part; genuinely disconnected land shows as
  /// multiple parts. Empty when the RPC didn't provide geometry.
  final List<List<List<LatLng>>> polygonParts;

  /// Centroid of the polygon — useful for placing labels / markers.
  /// Falls back to the first polygon point if not provided by the RPC.
  final LatLng? center;

  final DateTime? captureTime;
  final DateTime? lastActivityTime;
  final DateTime? protectedUntil;
  final DateTime? shieldUntil;
  final DateTime? cooldownUntil; // When territory attack cooldown expires

  Territory({
    required this.id,
    required this.userId,
    required this.username,
    required this.color,
    this.energy = 0,
    this.polygonPoints = const [],
    this.polygonParts = const [],
    this.center,
    this.captureTime,
    this.lastActivityTime,
    this.protectedUntil,
    this.shieldUntil,
    this.cooldownUntil,
  });

  factory Territory.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    String parseUsername(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map) return parseString(raw['username']);
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        return parseString((raw.first as Map)['username']);
      }
      return parseString(raw);
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    bool isValidLatLng(double lat, double lng) {
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    }

    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    LatLng? parsePolygonPoint(dynamic rawPoint) {
      if (rawPoint is Map) {
        final lat = toDouble(rawPoint['lat'] ?? rawPoint['latitude'] ?? rawPoint['y']);
        final lng = toDouble(rawPoint['lng'] ?? rawPoint['longitude'] ?? rawPoint['x']);
        if (lat != null && lng != null) return LatLng(lat, lng);
        return null;
      }

      if (rawPoint is List && rawPoint.length >= 2) {
        final first = toDouble(rawPoint[0]);
        final second = toDouble(rawPoint[1]);
        if (first == null || second == null) return null;
        if (isValidLatLng(first, second)) {
          return LatLng(first, second);
        }
        if (isValidLatLng(second, first)) {
          return LatLng(second, first);
        }
      }

      return null;
    }

    List<dynamic>? normalizePolygonCoordinates(dynamic value) {
      if (value is Map) {
        if (value.containsKey('coordinates')) {
          return normalizePolygonCoordinates(value['coordinates']);
        }
        if (value.containsKey('polygon_points')) {
          return normalizePolygonCoordinates(value['polygon_points']);
        }
        return [value];
      }

      if (value is List) {
        var list = value;
        while (list.isNotEmpty &&
            list.first is List &&
            (list.first as List).isNotEmpty &&
            (list.first as List).first is List) {
          list = list.first as List;
        }
        return list.cast<dynamic>();
      }

      return null;
    }

    // Parse polygon_points array: [{lat: x, lng: y}, ...]
    // This supports nested GeoJSON-style coordinates, stringified JSON,
    // and both {lat,lng} and [lng,lat] point representations.
    List<LatLng> parsePolygonPoints(dynamic raw) {
      if (raw == null) return [];
      try {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        final coordinates = normalizePolygonCoordinates(decoded);
        if (coordinates == null || coordinates.isEmpty) return [];

        return coordinates
            .map(parsePolygonPoint)
            .whereType<LatLng>()
            .toList();
      } catch (e, st) {
        developer.log('[Territory] Failed to parse polygon_points: $e',
            stackTrace: st);
        return [];
      }
    }

    // Parse centroid: {lat: x, lng: y} — optional field from RPC
    LatLng? parseCentroid(dynamic raw) {
      if (raw == null) return null;
      try {
        final lat = (raw['lat'] as num?)?.toDouble();
        final lng = (raw['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        return LatLng(lat, lng);
      } catch (_) {
        return null;
      }
    }

    // Parse GeoJSON Polygon/MultiPolygon into parts → rings → points.
    // GeoJSON positions are strictly [lng, lat], so no order guessing.
    List<List<LatLng>> parseGeoJsonRings(List rings) {
      final out = <List<LatLng>>[];
      for (final ring in rings) {
        if (ring is! List) continue;
        final points = <LatLng>[];
        for (final pt in ring) {
          if (pt is List && pt.length >= 2) {
            final lng = toDouble(pt[0]);
            final lat = toDouble(pt[1]);
            if (lat != null && lng != null && isValidLatLng(lat, lng)) {
              points.add(LatLng(lat, lng));
            }
          }
        }
        if (points.length >= 3) out.add(points);
      }
      return out;
    }

    List<List<List<LatLng>>> parseGeoJsonParts(dynamic raw) {
      if (raw == null) return const [];
      try {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        if (decoded is! Map) return const [];
        final type = decoded['type']?.toString();
        final coordinates = decoded['coordinates'];
        if (coordinates is! List) return const [];

        if (type == 'Polygon') {
          final part = parseGeoJsonRings(coordinates);
          return part.isEmpty ? const [] : [part];
        }
        if (type == 'MultiPolygon') {
          final parts = <List<List<LatLng>>>[];
          for (final poly in coordinates) {
            if (poly is! List) continue;
            final part = parseGeoJsonRings(poly);
            if (part.isNotEmpty) parts.add(part);
          }
          return parts;
        }
        return const [];
      } catch (e, st) {
        developer.log('[Territory] Failed to parse geojson: $e',
            stackTrace: st);
        return const [];
      }
    }

    final polygonParts = parseGeoJsonParts(json['geojson']);
    var polygonPoints = parsePolygonPoints(json['polygon_points']);

    // Belt and braces: if only the structured geometry arrived, derive the
    // flat legacy list from the largest part's exterior ring.
    if (polygonPoints.isEmpty && polygonParts.isNotEmpty) {
      var largest = polygonParts.first.first;
      for (final part in polygonParts) {
        if (part.first.length > largest.length) largest = part.first;
      }
      polygonPoints = largest;
    }

    // Derive center: prefer explicit centroid from RPC, fall back to
    // the average of polygon points, or the stored lat/lng columns.
    LatLng? center = parseCentroid(json['centroid']);
    if (center == null && polygonPoints.isNotEmpty) {
      final avgLat =
          polygonPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
          polygonPoints.length;
      final avgLng =
          polygonPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
          polygonPoints.length;
      center = LatLng(avgLat, avgLng);
    }
    if (center == null && json['lat'] != null && json['lng'] != null) {
      center = LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
    }

    final username = parseUsername(
      json['username'] ??
          json['profile'] ??
          json['owner'] ??
          json['user'] ??
          json['profiles'],
    );

    return Territory(
      id: parseString(json['id']),
      userId: parseString(json['user_id']),
      username: username.isNotEmpty ? username : 'Unknown',
      color: json['color']?.toString() ?? '#0D968B',
      energy: json['energy'] ?? 0,
      polygonPoints: polygonPoints,
      polygonParts: polygonParts,
      center: center,
      captureTime: parseDate(json['capture_time']),
      lastActivityTime: parseDate(json['last_activity_time']),
      protectedUntil: parseDate(
        json['protected_until'] ?? json['protection_until'],
      ),
      shieldUntil: parseDate(json['shield_until']),
      cooldownUntil: parseDate(json['cooldown_until']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'color': color,
      'energy': energy,
      // polygon_points is read-only from the DB.
      'capture_time': captureTime?.toIso8601String(),
      'last_activity_time': lastActivityTime?.toIso8601String(),
      'protected_until': protectedUntil?.toIso8601String(),
      'shield_until': shieldUntil?.toIso8601String(),
      'cooldown_until': cooldownUntil?.toIso8601String(),
    };
  }

  Territory copyWith({
    String? id,
    String? userId,
    String? username,
    String? color,
    int? energy,
    List<LatLng>? polygonPoints,
    List<List<List<LatLng>>>? polygonParts,
    LatLng? center,
    DateTime? captureTime,
    DateTime? lastActivityTime,
    DateTime? protectedUntil,
    DateTime? shieldUntil,
    DateTime? cooldownUntil,
  }) {
    return Territory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      color: color ?? this.color,
      energy: energy ?? this.energy,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      polygonParts: polygonParts ?? this.polygonParts,
      center: center ?? this.center,
      captureTime: captureTime ?? this.captureTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      protectedUntil: protectedUntil ?? this.protectedUntil,
      shieldUntil: shieldUntil ?? this.shieldUntil,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
    );
  }

  /// True if the territory has a drawable polygon.
  bool get hasPolygon => polygonParts.isNotEmpty || polygonPoints.length >= 3;

  /// Geometry to render: structured parts when available, otherwise the
  /// legacy flat ring wrapped as a single part. Each part is a list of rings
  /// (ring 0 = exterior, rest = holes).
  List<List<List<LatLng>>> get renderParts {
    if (polygonParts.isNotEmpty) return polygonParts;
    if (polygonPoints.length >= 3) return [
      [polygonPoints],
    ];
    return const [];
  }

  bool isProtected() {
    final now = DateTime.now();
    if (protectedUntil != null && protectedUntil!.isAfter(now)) return true;
    if (shieldUntil != null && shieldUntil!.isAfter(now)) return true;
    return false;
  }

  bool hasShield() {
    if (shieldUntil == null) return false;
    return shieldUntil!.isAfter(DateTime.now());
  }

  int calculateEnergy(String currentUserId, LatLng? homeBase, DateTime now) {
    int e = energy == 0 ? 10 : energy;

    if (lastActivityTime != null) {
      final la = lastActivityTime!;
      if (la.year == now.year && la.month == now.month && la.day == now.day) {
        e += 5;
      }
    }

    if (captureTime != null && now.difference(captureTime!).inHours > 48) {
      e += 10;
    }

    return e > 60 ? 60 : e;
  }
}
