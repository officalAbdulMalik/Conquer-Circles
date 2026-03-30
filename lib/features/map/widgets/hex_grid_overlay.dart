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
    final energyRatio = (territory.energy / 60.0).clamp(0.0, 1.0);

    Color fillColor;
    Color strokeColor;
    int strokeWidth;

    switch (status) {
      case TerritoryStatus.owned:
        final opacity = 0.50 + energyRatio * 0.40;
        fillColor = const Color(0xFF0D968B).withValues(alpha: opacity);
        strokeColor = Colors.white.withValues(alpha: 0.8);
        strokeWidth = 2;

      case TerritoryStatus.protected:
        fillColor = const Color(
          0xFF06F5E9,
        ).withValues(alpha: 0.55 + energyRatio * 0.3);
        strokeColor = const Color(0xFF06F5E9);
        strokeWidth = 3;

      case TerritoryStatus.enemy:
        fillColor = const Color(
          0xFFFF6B35,
        ).withValues(alpha: 0.40 + energyRatio * 0.30);
        strokeColor = const Color(0xFFFF6B35);
        strokeWidth = 2;

      case TerritoryStatus.neutral:
        fillColor = const Color(0xFF94A3B8).withValues(alpha: 0.08);
        strokeColor = const Color(0xFF94A3B8).withValues(alpha: 0.20);
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

class TileInfoSheet extends StatelessWidget {
  final Territory tile;
  final String? currentUserId;
  final VoidCallback? onClaim;
  final VoidCallback? onActivateShield;

  const TileInfoSheet({
    super.key,
    required this.tile,
    this.currentUserId,
    this.onClaim,
    this.onActivateShield,
  });

  @override
  Widget build(BuildContext context) {
    final status = HexGridOverlay._getStatus(tile, currentUserId);
    final energyRatio = (tile.energy / 60.0).clamp(0.0, 1.0);

    Color accentColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case TerritoryStatus.owned:
        accentColor = const Color(0xFF0D968B);
        statusLabel = 'Your Territory';
        statusIcon = Icons.shield_rounded;
      case TerritoryStatus.protected:
        accentColor = const Color(0xFF06F5E9);
        statusLabel = tile.hasShield() ? 'Shielded' : 'Protected';
        statusIcon = tile.hasShield()
            ? Icons.security_rounded
            : Icons.lock_rounded;
      case TerritoryStatus.enemy:
        accentColor = const Color(0xFFFF6B35);
        statusLabel = 'Enemy Territory';
        statusIcon = Icons.warning_amber_rounded;
      case TerritoryStatus.neutral:
        accentColor = const Color(0xFF64748B);
        statusLabel = 'Unclaimed';
        statusIcon = Icons.flag_outlined;
    }

    final canClaim =
        status == TerritoryStatus.neutral ||
        (status == TerritoryStatus.enemy && !tile.isProtected());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Territory ${tile.id.substring(0, 6)}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (tile.username.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tile.username,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: 'TERRITORY ENERGY',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${tile.energy} / 60',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(energyRatio * 100).toInt()}%',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: energyRatio,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (tile.isProtected()) ...[
            if (tile.shieldUntil != null &&
                tile.shieldUntil!.isAfter(DateTime.now()))
              _InfoRow(
                label: 'ABSENCE SHIELD ACTIVE',
                child: _ProtectionTimer(
                  until: tile.shieldUntil!,
                  icon: Icons.security_rounded,
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (tile.lastVisited != null) ...[
            _InfoRow(
              label: 'LAST ACTIVITY',
              child: Text(
                _formatRelativeTime(tile.lastVisited!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          if (canClaim && onClaim != null)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      status == TerritoryStatus.neutral
                          ? Icons.flag_rounded
                          : Icons.bolt_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status == TerritoryStatus.neutral
                          ? 'Claim Territory'
                          : 'Attack Territory',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (status == TerritoryStatus.owned)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Walk through to reinforce',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (!tile.hasShield() && onActivateShield != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: onActivateShield,
                      icon: const Icon(Icons.security_rounded, size: 20),
                      label: const Text('Activate 7-Day Shield'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: const Color(0xFF06F5E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFF06F5E9),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ProtectionTimer extends StatelessWidget {
  final DateTime until;
  final IconData icon;
  const _ProtectionTimer({required this.until, this.icon = Icons.lock_clock});

  @override
  Widget build(BuildContext context) {
    final remaining = until.difference(DateTime.now());
    final d = remaining.inDays;
    final h = remaining.inHours % 24;
    final m = remaining.inMinutes % 60;

    String timeStr = '';
    if (d > 0) timeStr += '${d}d ';
    timeStr += '${h}h ${m}m remaining';

    return Row(
      children: [
        Icon(icon, color: const Color(0xFF06F5E9), size: 16),
        const SizedBox(width: 6),
        Text(
          timeStr,
          style: const TextStyle(
            color: Color(0xFF06F5E9),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
