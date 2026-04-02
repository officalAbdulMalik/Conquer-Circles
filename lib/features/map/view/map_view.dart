import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/features/map/widgets/hexa_tile_painter.dart';
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
import '../widgets/attack_history_sheet.dart';
import '../widgets/map_search_overlay.dart';
import '../../chatbot/widgets/quick_action_chips.dart';
import '../widgets/tile_handler.dart';
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
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final MapTileHandler _tileHandler = MapTileHandler();
  final SupabaseService _supabase = SupabaseService();
  Map<String, Offset> _computedTileCenters = {};

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

      if (result == previous?.lastAttackResult) return;

      final action = result['action'] as String?;
      if (action == null) return;

      final variant = AttackToastController.variantFromAction(action);
      if (variant == null && action != 'not_friends') return;

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
      }
    });
  }

  void _triggerGreenFlash() {
    _showGreenFlash.value = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _showGreenFlash.value = false;
    });
  }

  void _updateTileCenters() async {
    if (_mapController == null) return;
    
    final mapState = ref.read(mapProvider);
    if (mapState.visibleTiles.isEmpty) return;
    
    final Map<String, Offset> newCenters = {};
    for (final tile in mapState.visibleTiles) {
      final latLng = H3Utils.h3ToLatLng(tile.tileId);
      if (latLng != null) {
        final screenPos = await _mapController!.getScreenCoordinate(latLng);
        newCenters[tile.tileId] = Offset(
          screenPos.x.toDouble(), 
          screenPos.y.toDouble(),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _computedTileCenters = newCenters;
      });
    }
  }

  void _handleMapTap(Offset localPos) {
    String? tappedTileId;
    double minDistance = 40.0; // Hex radius approximately
    
    _computedTileCenters.forEach((tileId, screenPos) {
      final dist = (localPos - screenPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        tappedTileId = tileId;
      }
    });
    
    if (tappedTileId != null) {
      final tile = ref.read(mapProvider).visibleTiles
          .firstWhere((t) => t.tileId == tappedTileId);
      
      ref.read(mapProvider.notifier).selectTile(tappedTileId);
      
      final userLoc = ref.read(mapProvider).userLocation;
      if (userLoc != null) {
        _tileHandler.handleTileTap(
          context: context,
          tile: tile,
          lat: userLoc.latitude,
          lng: userLoc.longitude,
        );
      }
    } else {
      ref.read(mapProvider.notifier).selectTile(null);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _toastController.dispose();
    _showGreenFlash.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);
    final attackEnergy = ref.watch(stepProvider.select((s) => s.attackEnergy));

    final hexPolygons = HexGridOverlay.build(
      mapState.nearbyTerritories,
      _supabase.currentUser?.id,
      homeBase: mapState.homeBase,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
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
              onCameraIdle: () async {
                final bounds = await _mapController?.getVisibleRegion();
                if (bounds != null) {
                  ref.read(mapProvider.notifier).loadTerritoriesForBounds(bounds);
                }
                _updateTileCenters();
              },
              onCameraMove: (_) => _updateTileCenters(),
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D968B)),
            ),

          _buildMapInteractionLayer(),
          _buildTopOverlays(context, mapState),
          _buildSideControls(context, mapState, attackEnergy),
          _buildBottomOverlays(context, mapState),
        ],
      ),
    );
  }

  Widget _buildMapInteractionLayer() {
    return Stack(
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: HexTilePainter(
              tiles: ref.watch(mapProvider).visibleTiles,
              tileCenters: _computedTileCenters,
              currentUserId: _supabase.currentUser?.id ?? '',
              selectedTileId: ref.watch(mapProvider).selectedTileId,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        GestureDetector(
          onTapDown: (details) => _handleMapTap(details.localPosition),
        ),
      ],
    );
  }

  Widget _buildTopOverlays(BuildContext context, MapState mapState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          children: [
            MapHeader(
              title: 'Conquer Circles',
              subtitle: mapState.isWalking ? 'Live Session • Active' : 'Ready to Start',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MapSearchOverlay(
                controller: _searchController,
                onSearch: (val) {
                  _searchFocusNode.unfocus();
                },
              ),
            ),
            const SizedBox(height: 12),
            QuickActionChips(
              chips: const ['Home Base', 'My Territories', 'Nearest Rival'],
              onChipTapped: (chip) {
                if (chip == 'Home Base' && mapState.homeBase != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(mapState.homeBase!),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideControls(BuildContext context, MapState mapState, int attackEnergy) {
    final speedMps = mapState.currentSpeedMps ?? 0.0;
    final speedKmh = speedMps * 3.6;

    return Stack(
      children: [
        Positioned(top: 250, left: 16, child: _TerritoryLegend()),
        Positioned(
          top: 306,
          left: 16,
          child: SpeedIndicatorBadge(
            speedKmh: speedKmh,
            visible: mapState.isWalking,
          ),
        ),
        Positioned(
          top: 250,
          right: 16 + 48 + 12,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _supabase.getProfile(),
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
        Positioned(
          top: 250,
          right: 16,
          child: Column(
            children: [
              MapActionControls(
                onZoomIn: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                onZoomOut: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
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
              GestureDetector(
                onTap: () => showAttackHistorySheet(context, attackEnergy: attackEnergy),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.history, color: Color(0xFFFF9800), size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomOverlays(BuildContext context, MapState mapState) {
    final mapNotifier = ref.read(mapProvider.notifier);
    final currentUserId = _supabase.currentUser?.id;

    return Stack(
      children: [
        if (mapState.isWalking)
          Positioned(
            bottom: 180,
            left: 16,
            right: 16,
            child: MapStatsOverlay(
              duration: _formatDuration(mapState),
              distance: _formatDistance(mapState),
              pace: '—',
              territoryCount: mapState.nearbyTerritories
                  .where((t) => t.userId == currentUserId)
                  .length
                  .toString(),
            ),
          ),
        Positioned(
          bottom: 90,
          left: 16,
          right: 16,
          child: MapActionButton(
            type: mapState.isWalking ? MapActionType.pause : MapActionType.start,
            onTap: () {
              if (mapState.isWalking) {
                mapNotifier.stopWalk();
              } else {
                mapNotifier.startWalk();
              }
            },
          ),
        ),
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: AttackToastOverlay(controller: _toastController),
        ),
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
    );
  }

  String _formatDuration(MapState state) => '0:00';

  String _formatDistance(MapState state) {
    if (state.activePath.length < 2) return '0.0';
    double totalM = 0;
    for (int i = 1; i < state.activePath.length; i++) {
      totalM += H3Utils.distanceMeters(state.activePath[i - 1], state.activePath[i]);
    }
    return (totalM / 1000).toStringAsFixed(1);
  }

  Set<Polyline> _buildPolylines(MapState state, MapNotifier notifier) {
    if (state.activePath.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('active_path'),
        points: state.activePath,
        color: const Color(0xFF0D968B),
        width: 5,
      ),
    };
  }
}

class _TerritoryLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendItem(color: Color(0xFF0D968B), label: 'Yours'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFF0D968B), label: 'Home Base', isHome: true),
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
  const _LegendItem({required this.color, required this.label, this.isHome = false});

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
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SmallStatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _SmallStatBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
