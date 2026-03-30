import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/models/map_model.dart';
import 'package:test_steps/features/map/utils/h3_utils.dart';
import 'package:test_steps/features/map/widgets/hex_grid_overlay.dart';
import '../widgets/map_header.dart';
import '../widgets/map_action_controls.dart';
import '../widgets/map_stats_overlay.dart';
import '../widgets/map_action_button.dart';
import '../widgets/attack_energy_badge.dart';
import '../widgets/speed_indicator_badge.dart';
import '../widgets/attack_toast.dart';
import '../widgets/tile_info_sheet.dart';
import '../widgets/attack_history_sheet.dart';
import '../../../services/attack_service.dart'; // stepProvider
import '../../../services/supabase_service.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? _mapController;
  Set<Polygon> hexGrid = {};

  /// Toast controller — lives here so all child code can call it
  final AttackToastController _toastController = AttackToastController();

  /// Controller for the green claim flash animation
  final ValueNotifier<bool> _showGreenFlash = ValueNotifier<bool>(false);

  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#0f172a"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#64748b"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0f172a"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#334155"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#475569"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#0f2a1a"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#1e4d2b"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#475569"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#1e3a5f"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#94a3b8"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#334155"}]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0c1524"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#1e3a5f"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    initLoad();
  }

  initLoad() async {
    ref.listen<MapState>(mapProvider, (previous, next) {
      final result = next.lastAttackResult;
      if (result == null) return;

      // Only show toast when result changes
      if (result == previous?.lastAttackResult) return;

      final action = result['action'] as String?;
      if (action == null) return;

      final variant = AttackToastController.variantFromAction(action);
      if (variant == null && action != 'not_friends') return;

      // Update energy immediately in step provider if available
      if (result['attacker_energy_left'] != null) {
        ref
            .read(stepProvider.notifier)
            .updateEnergy(result['attacker_energy_left'] as int);
      }

      switch (action) {
        case 'captured':
          final defender = result['defender_id'] ?? 'rival';
          _toastController.show(variant!, 'You captured $defender\'s tile!');
          break;
        case 'damaged':
          final energyAfter = result['tile_energy_after'] ?? 0;
          _toastController.show(
            variant!,
            'Tile damaged — $energyAfter energy left',
          );
          break;
        case 'protected':
          final hours = result['hours_remaining'] ?? 0;
          final reason = result['reason'] == 'tile'
              ? 'tile shield'
              : 'walk shield';
          _toastController.show(
            variant!,
            'Protected — ${hours}h remaining ($reason)',
          );
          break;
        case 'cooldown':
          final mins = result['minutes_left'] ?? 0;
          _toastController.show(variant!, 'Cooldown — $mins min remaining');
          break;
        case 'no_energy':
          final needed = result['energy_needed'] ?? 0;
          _toastController.show(
            variant!,
            'No energy — walk ${needed * 100} more steps',
          );
          break;
        case 'claimed':
          _toastController.show(variant!, 'Tile claimed!');
          _triggerGreenFlash();
          break;
        case 'not_friends':
          break;
      }
    });
  }

  void _triggerGreenFlash() {
    _showGreenFlash.value = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _showGreenFlash.value = false;
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _toastController.dispose();
    _showGreenFlash.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng tapPoint) {
    final mapState = ref.read(mapProvider);
    final h3Index = H3Utils.latLngToH3(tapPoint);
    final mapNotifier = ref.read(mapProvider.notifier);
    final currentUserId = mapNotifier.currentUser?.id;

    // Find tapped territory
    final tappedTile = mapState.nearbyTerritories
        .where((t) => t.id == h3Index)
        .firstOrNull;

    // Show tile info sheet (null = unclaimed)
    showTileInfoSheet(
      context: context,
      tile: tappedTile,
      currentUserId: currentUserId,
      toastController: _toastController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);
    final currentUserId = mapNotifier.currentUser?.id;

    // Attack energy from step provider
    final attackEnergy = ref.watch(stepProvider.select((s) => s.attackEnergy));

    // Walking speed from map state (m/s → km/h)
    final speedMps = mapState.currentSpeedMps ?? 0.0;
    final speedKmh = speedMps * 3.6;

    // Build hex polygons
    final hexPolygons = HexGridOverlay.build(
      mapState.nearbyTerritories,
      currentUserId,
      homeBase: mapState.homeBase,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Map Layer ────────────────────────────────────────────────────────
          if (mapState.userLocation != null || mapState.homeBase != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: mapState.userLocation ?? mapState.homeBase!,
                zoom: 16.0,
              ),
              style: _mapStyle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              polylines: _buildPolylines(mapState, mapNotifier),
              polygons: {...hexGrid, ...hexPolygons},
              onTap: _onMapTap,
              onCameraIdle: () async {
                final bounds = await _mapController?.getVisibleRegion();
                if (bounds != null) {
                  mapNotifier.loadTerritoriesForBounds(bounds);
                }
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D968B)),
            ),

          // ── Top UI ──────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  MapHeader(
                    title: 'Conquer Circles',
                    subtitle: mapState.isWalking
                        ? 'Live Session • Active'
                        : 'Ready to Start',
                  ),
                ],
              ),
            ),
          ),

          // ── Territory Legend ─────────────────────────────────────────────────
          Positioned(top: 140, left: 16, child: _TerritoryLegend()),

          // ── Speed Indicator Badge (top-left, only while walking) ─────────────
          Positioned(
            top: 196,
            left: 16,
            child: SpeedIndicatorBadge(
              speedKmh: speedKmh,
              visible: mapState.isWalking,
            ),
          ),

          // ── Attack Energy Badge (top-right) ──────────────────────────────────
          Positioned(
            top: 140,
            right: 16 + 48 + 12, // inset left of the action controls
            child: FutureBuilder<Map<String, dynamic>?>(
              future: SupabaseService().getProfile(),
              builder: (context, snapshot) {
                final tiles = snapshot.data?['total_tiles_owned'] ?? 0;
                return Row(
                  children: [
                    _SmallStatBadge(
                      icon: Icons.hexagon,
                      value: '$tiles',
                      color: const Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 8),
                    AttackEnergyBadge(energy: attackEnergy),
                  ],
                );
              },
            ),
          ),

          // ── Side Controls ───────────────────────────────────────────────────
          Positioned(
            top: 140,
            right: 16,
            child: Column(
              children: [
                MapActionControls(
                  onZoomIn: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  onZoomOut: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  onMyLocation: () {
                    if (mapState.userLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(mapState.userLocation!),
                      );
                    }
                  },
                  onLayersToggled: () {},
                ),
                const SizedBox(height: 12),

                // ── Attack History button ────────────────────────────────────
                GestureDetector(
                  onTap: () => showAttackHistorySheet(
                    context,
                    attackEnergy: attackEnergy,
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Color(0xFFFF9800),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tile Count Badge ─────────────────────────────────────────────────
          if (mapState.nearbyTerritories.isNotEmpty)
            Positioned(
              bottom: 180,
              left: 16,
              child: _TileCountBadge(
                ownedCount: mapState.nearbyTerritories
                    .where((t) => t.userId == currentUserId)
                    .length,
                totalCount: mapState.nearbyTerritories.length,
              ),
            ),

          // ── Bottom Stats & Action ───────────────────────────────────────────
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mapState.isWalking)
                  MapStatsOverlay(
                    duration: _formatDuration(mapState),
                    distance: _formatDistance(mapState),
                    pace: '—',
                    territoryCount: mapState.nearbyTerritories
                        .where((t) => t.userId == currentUserId)
                        .length
                        .toString()
                        .padLeft(2, '0'),
                  ),
                const SizedBox(height: 16),
                MapActionButton(
                  type: mapState.isWalking
                      ? MapActionType.pause
                      : MapActionType.start,
                  onTap: () {
                    if (mapState.isWalking) {
                      mapNotifier.stopWalk();
                    } else {
                      mapNotifier.startWalk();
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Attack Toast Overlay (bottom-center) ─────────────────────────────
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: AttackToastOverlay(controller: _toastController),
          ),

          // ── Green Flash Overlay ─────────────────────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: _showGreenFlash,
            builder: (context, show, child) {
              return IgnorePointer(
                child: AnimatedOpacity(
                  opacity: show ? 0.3 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(color: Colors.green),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(MapState state) {
    return '0:00';
  }

  String _formatDistance(MapState state) {
    if (state.activePath.length < 2) return '0.0';
    double totalM = 0;
    for (int i = 1; i < state.activePath.length; i++) {
      totalM += H3Utils.distanceMeters(
        state.activePath[i - 1],
        state.activePath[i],
      );
    }
    return (totalM / 1000).toStringAsFixed(1);
  }

  Set<Polyline> _buildPolylines(MapState state, MapNotifier notifier) {
    final Set<Polyline> polylines = {};

    if (state.activePath.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_path'),
          points: state.activePath,
          color: const Color(0xFF0D968B),
          width: 5,
        ),
      );
    }

    return polylines;
  }
}

// ---------------------------------------------------------------------------
// Supporting Widgets
// ---------------------------------------------------------------------------

class _TerritoryLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendItem(color: Color(0xFF0D968B), label: 'Yours'),
          SizedBox(height: 4),
          _LegendItem(
            color: Color(0xFF0D968B),
            label: 'Home Base',
            isHome: true,
          ),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFF06F5E9), label: 'Protected'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFFFF6B35), label: 'Enemy'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFF94A3B8), label: 'Neutral'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isHome;
  const _LegendItem({
    required this.color,
    required this.label,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isHome ? Border.all(color: Colors.white, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TileCountBadge extends StatelessWidget {
  final int ownedCount;
  final int totalCount;
  const _TileCountBadge({required this.ownedCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D968B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0D968B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hexagon, color: Color(0xFF0D968B), size: 14),
          const SizedBox(width: 6),
          Text(
            '$ownedCount tiles owned',
            style: const TextStyle(
              color: Color(0xFF0D968B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SmallStatBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
