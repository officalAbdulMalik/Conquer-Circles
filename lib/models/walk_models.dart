import 'package:google_maps_flutter/google_maps_flutter.dart';

class WalkingSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final double? totalDistanceM;
  final int? durationSeconds;
  final double? avgSpeedMps;
  final int? pointCount;
  final double? centerLat;
  final double? centerLng;

  WalkingSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    required this.status,
    this.totalDistanceM,
    this.durationSeconds,
    this.avgSpeedMps,
    this.pointCount,
    this.centerLat,
    this.centerLng,
  });

  factory WalkingSession.fromJson(Map<String, dynamic> json) {
    return WalkingSession(
      id: json['id'],
      userId: json['user_id'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      status: json['status'],
      totalDistanceM: json['total_distance_m']?.toDouble(),
      durationSeconds: json['duration_seconds'],
      avgSpeedMps: json['avg_speed_mps']?.toDouble(),
      pointCount: json['point_count'],
      centerLat: json['center_lat']?.toDouble(),
      centerLng: json['center_lng']?.toDouble(),
    );
  }
}

class LocationPoint {
  final int? id;
  final String sessionId;
  final String userId;
  final DateTime recordedAt;
  final int sequenceNum;
  final double latitude;
  final double longitude;
  final double? altitudeM;
  final double? accuracyM;
  final double? speedMps;
  final double? bearingDeg;

  LocationPoint({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.recordedAt,
    required this.sequenceNum,
    required this.latitude,
    required this.longitude,
    this.altitudeM,
    this.accuracyM,
    this.speedMps,
    this.bearingDeg,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'recorded_at': recordedAt.toIso8601String(),
      'sequence_num': sequenceNum,
      'latitude': latitude,
      'longitude': longitude,
      'altitude_m': altitudeM,
      'accuracy_m': accuracyM,
      'speed_mps': speedMps,
      'bearing_deg': bearingDeg,
    };
  }
}

class Territory {
  final String id; // DB row id (UUID) or user_id depending on your schema
  final String userId; // Owner
  final String username;
  final String color;
  final int energy;

  /// The polygon boundary returned by the get_territories_nearby RPC.
  /// Populated from the `polygon_points` JSON array: [{lat, lng}, ...]
  /// Empty list means no polygon has been saved yet for this territory.
  final List<LatLng> polygonPoints;

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

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Parse polygon_points array: [{lat: x, lng: y}, ...]
    // This is produced by the get_territories_nearby RPC using ST_DumpPoints.
    List<LatLng> parsePolygonPoints(dynamic raw) {
      if (raw == null) return [];
      try {
        final List list = raw is List ? raw : [];
        return list
            .map((p) {
              final lat = (p['lat'] as num?)?.toDouble();
              final lng = (p['lng'] as num?)?.toDouble();
              if (lat == null || lng == null) return null;
              return LatLng(lat, lng);
            })
            .whereType<LatLng>()
            .toList();
      } catch (e) {
        print('[Territory] Failed to parse polygon_points: $e');
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

    final polygonPoints = parsePolygonPoints(json['polygon_points']);

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

    return Territory(
      id: parseString(json['id']),
      userId: parseString(json['user_id']),
      username: json['username']?.toString() ?? 'Unknown',
      color: json['color']?.toString() ?? '#0D968B',
      energy: json['energy'] ?? 0,
      polygonPoints: polygonPoints,
      center: center,
      captureTime: parseDate(json['capture_time']),
      lastActivityTime: parseDate(json['last_activity_time']),
      protectedUntil: parseDate(json['protected_until']),
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
      // polygon_points is read-only from the DB — never write it from Flutter.
      // The SQL end_walking_session function owns the geom column.
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
      center: center ?? this.center,
      captureTime: captureTime ?? this.captureTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      protectedUntil: protectedUntil ?? this.protectedUntil,
      shieldUntil: shieldUntil ?? this.shieldUntil,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
    );
  }

  /// True if the territory has a drawable polygon.
  bool get hasPolygon => polygonPoints.length >= 3;

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
