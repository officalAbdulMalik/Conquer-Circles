import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/features/map/widgets/hexa_tile_painter.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/models/map_model.dart';
import 'package:test_steps/features/map/widgets/hex_grid_overlay.dart';
import 'package:test_steps/widgets/shared/map_view.dart';
import '../widgets/map_action_controls.dart';
import '../widgets/map_stats_overlay.dart';
import '../widgets/map_action_button.dart';
import '../widgets/attack_energy_badge.dart';
import '../widgets/speed_indicator_badge.dart';
import '../widgets/attack_toast.dart';
import '../widgets/attack_history_sheet.dart';
import '../widgets/tile_handler.dart';
import '../widgets/territory_label.dart';
import '../widgets/territory_conditions_overlay.dart';
import '../widgets/territory_detail_sheet.dart';
import '../widgets/location_indicator.dart';
import '../../../services/attack_service.dart';
import '../../../services/supabase_service.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? _mapController;
  Set<Polygon> _hexGrid = {};

  final MapTileHandler _tileHandler = MapTileHandler();
  final SupabaseService _supabase = SupabaseService();
  Map<String, Offset> _computedTileCenters = {};

  final AttackToastController _toastController = AttackToastController();
  final ValueNotifier<bool> _showGreenFlash = ValueNotifier<bool>(false);

  // Cached so it doesn't re-fire on every build
  late final Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Cache the profile future once — not on every build
    _profileFuture = _supabase.getProfile();
  }

  // ── Listener is registered in didChangeDependencies, not build ──────────────
  // This ensures it is set up exactly once and is not re-registered on rebuilds.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupAttackResultListener();
  }

  ProviderSubscription<MapState>? _attackSubscription;

  void _setupAttackResultListener() {
    // Cancel any previous subscription before creating a new one
    _attackSubscription?.close();
    _attackSubscription = ref.listenManual<MapState>(
      mapProvider,
      (previous, next) {
        final result = next.lastAttackResult;
        if (result == null) return;
        if (result == previous?.lastAttackResult) return;

        final action = result['action'] as String?;
        if (action == null) return;

        final variant = AttackToastController.variantFromAction(action);
        if (variant == null && action != 'not_friends') return;

        final energyLeft = result['attacker_energy_left'];
        if (energyLeft != null) {
          Future.microtask(() {
            if (mounted) {
              ref.read(stepProvider.notifier).updateEnergy(energyLeft as int);
            }
          });
        }

        _handleAttackAction(action, result, variant);
      },
    );
  }

  void _handleAttackAction(
    String action,
    Map<String, dynamic> result,
    AttackToastVariant? variant,
  ) {
    switch (action) {
      case 'captured':
        final defender = result['defender_id'] ?? 'rival';
        _toastController.show(variant!, 'You captured $defender\'s tile!');
      case 'damaged':
        final energyAfter = result['tile_energy_after'] ?? 0;
        _toastController.show(variant!, 'Tile damaged — $energyAfter energy left');
      case 'protected':
        final hours = result['hours_remaining'] ?? 0;
        final reason = result['reason'] == 'tile' ? 'tile shield' : 'walk shield';
        _toastController.show(variant!, 'Protected — ${hours}h remaining ($reason)');
      case 'cooldown':
        final mins = result['minutes_left'] ?? 0;
        _toastController.show(variant!, 'Cooldown — $mins min remaining');
      case 'no_energy':
        final needed = result['energy_needed'] ?? 0;
        _toastController.show(variant!, 'No energy — walk ${needed * 100} more steps');
      case 'claimed':
        _toastController.show(variant!, 'Tile claimed!');
        _triggerGreenFlash();
    }
  }

  void _triggerGreenFlash() {
    _showGreenFlash.value = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _showGreenFlash.value = false;
    });
  }


  void _handleMapTap(Offset localPos) {
    String? tappedTileId;
    double minDistance = 40.0;

    _computedTileCenters.forEach((tileId, screenPos) {
      final dist = (localPos - screenPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        tappedTileId = tileId;
      }
    });

    final mapNotifier = ref.read(mapProvider.notifier);

    if (tappedTileId == null) {
      mapNotifier.selectTile(null);
      return;
    }

    final mapState = ref.read(mapProvider);
    final tile = mapState.visibleTiles.firstWhere((t) => t.tileId == tappedTileId);
    mapNotifier.selectTile(tappedTileId);

    final userLoc = mapState.userLocation;
    if (userLoc != null) {
      TerritoryDetailSheet.show(
        context,
        tile: tile,
        currentUserId: _supabase.currentUser?.id,
        onClaim: () => _tileHandler.handleTileTap(
          context: context,
          tile: tile,
          lat: userLoc.latitude,
          lng: userLoc.longitude,
        ),
      );
    }
  }

  @override
  void dispose() {
    _attackSubscription?.close();
    _mapController?.dispose();
    _toastController.dispose();
    _showGreenFlash.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final stepState = ref.watch(stepProvider);

    // Build hex polygons only when nearbyTerritories or homeBase changes,
    // not on every unrelated rebuild.
    final hexPolygons = HexGridOverlay.build(
      mapState.nearbyTerritories,
      _supabase.currentUser?.id,
      homeBase: mapState.homeBase,
    );

    final hasMapTarget =
        mapState.userLocation != null || mapState.homeBase != null;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Map or loading/error state ─────────────────────────────────
            if (hasMapTarget)
              GoogleMapLayer(
                hexGrid: _hexGrid,
                hexPolygons: hexPolygons,
                mapState: mapState,
                onMapCreated: (controller) => _mapController = controller,
                onCameraIdle: () async {
                  final bounds = await _mapController?.getVisibleRegion();
                  if (bounds != null) {
                    ref.read(mapProvider.notifier).loadTerritoriesForBounds(bounds);
                  }

                },
                onCameraMove: (_) {},
                buildPolylines: () => _buildPolylines(mapState),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D968B)),
              ),

            // ── Overlaid UI layers ─────────────────────────────────────────
            _buildMapInteractionLayer(mapState),
            _buildTerritoryConditionsPanel(mapState),
            _buildSideControls(context, mapState, stepState.attackEnergy),
            _buildBottomOverlays(
              context,
              mapState,
              stepState.steps,
              stepState.attackEnergy,
            ),
          ],
        ),
      ),
    );
  }

  // ── Layer builders ──────────────────────────────────────────────────────────

  Widget _buildMapInteractionLayer(MapState mapState) {
    return Stack(
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: HexTilePainter(
              tiles: mapState.visibleTiles,
              tileCenters: _computedTileCenters,
              currentUserId: _supabase.currentUser?.id ?? '',
              selectedTileId: mapState.selectedTileId,
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

  /// Build a panel showing nearby territories and their conditions
  /// (energy, protection, cooldown)
  Widget _buildTerritoryConditionsPanel(MapState mapState) {
    if (mapState.nearbyTerritories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show up to 3 closest territories
    final closeTerritory = mapState.nearbyTerritories.take(3).toList();

    return Positioned(
      top: 16,
      left: 16,
      right: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: closeTerritory
            .map((territory) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TerritoryConditionsOverlay(
                    territory: territory,
                    center: territory.center ?? mapState.userLocation
                        ?? const LatLng(0, 0),
                    zoomLevel: 15,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTerritoryLabels(BuildContext context, MapState mapState) {
    return Stack(
      children: mapState.visibleTiles.map((tile) {
        final center = _computedTileCenters[tile.tileId];
        if (center == null) return const SizedBox.shrink();

        if (tile.ownership == TileOwnership.neutral &&
            tile.tileId.hashCode % 5 != 0) {
          return const SizedBox.shrink();
        }

        final name = tile.ownerUsername ?? 'Zone ${tile.tileId.substring(0, 4)}';

        return Positioned(
          left: center.dx - 50,
          top: center.dy - 60,
          child: IgnorePointer(
            child: TerritoryLabel(
              name: name,
              progress: tile.energy.toDouble() * 1.6,
              themeColor: tile.displayColor,
              badgeText: tile.ownership == TileOwnership.mine ? '+15' : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationIndicator(BuildContext context, MapState mapState) {
    if (mapState.userLocation == null) return const SizedBox.shrink();

    return FutureBuilder<ScreenCoordinate>(
      future: _mapController?.getScreenCoordinate(mapState.userLocation!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final point = snapshot.data!;
        return Stack(
          children: [
            Positioned(
              left: point.x.toDouble() - 40,
              top: point.y.toDouble() - 40,
              child: const PulsingLocationIndicator(),
            ),
            Positioned(
              left: point.x.toDouble() - 50,
              top: point.y.toDouble() + 20,
              child: const Center(child: YouAreHereLabel()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSideControls(
    BuildContext context,
    MapState mapState,
    int attackEnergy,
  ) {
    final speedKmh = (mapState.currentSpeedMps ?? 0.0) * 3.6;

    return Stack(
      children: [
        Positioned(
          top: 50.sp,
          left: 16,
          child: _TerritoryLegend(),
        ),
        Positioned(
          top: 306.sp,
          left: 16.sp,
          child: SpeedIndicatorBadge(
            speedKmh: speedKmh,
            visible: mapState.isWalking,
          ),
        ),
        Positioned(
          top: 30.sp,
          right: 16.sp,
          child: FutureBuilder<Map<String, dynamic>?>(
            // Uses the cached future — does not re-fire on rebuild
            future: _profileFuture,
            builder: (context, snapshot) {
              final tiles = snapshot.data?['total_tiles_owned'] ?? 0;
              return Column(
                children: [
                  _SmallStatBadge(
                    icon: Icons.hexagon,
                    value: '$tiles',
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 8),
                  AttackEnergyBadge(energy: attackEnergy),
                ],
              );
            },
          ),
        ),
        Positioned(
          top: 150.sp,
          right: 16.sp,
          child: Column(
            children: [
              MapActionControls(
                onZoomIn: () =>
                    _mapController?.animateCamera(CameraUpdate.zoomIn()),
                onZoomOut: () =>
                    _mapController?.animateCamera(CameraUpdate.zoomOut()),
                onMyLocation: () {
                  final loc = mapState.userLocation;
                  if (loc != null) {
                    _mapController?.animateCamera(CameraUpdate.newLatLng(loc));
                  }
                },
                onLayersToggled: () {},
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    showAttackHistorySheet(context, attackEnergy: attackEnergy),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                    ),
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
      ],
    );
  }

  Widget _buildBottomOverlays(
    BuildContext context,
    MapState mapState,
    int steps,
    int attackEnergy,
  ) {
    // Read notifier once per call, not via ref.read inside a build subtree
    final mapNotifier = ref.read(mapProvider.notifier);
    final currentUserId = _supabase.currentUser?.id;

    return Stack(
      children: [
        if (mapState.isWalking)
          Positioned(
            bottom: 90.sp,
            left: 16.sp,
            right: 16.sp,
            child: MapStatsOverlay(
              steps: steps.toString(),
              kcal: (steps * 0.04).toStringAsFixed(0),
              zones: mapState.nearbyTerritories
                  .where((t) => t.userId == currentUserId)
                  .length
                  .toString(),
              energy: attackEnergy >= 1000
                  ? '${(attackEnergy / 1000).toStringAsFixed(1)}k'
                  : attackEnergy.toString(),
            ),
          ),
        Positioned(
          bottom: 10,
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
          builder: (context, show, _) => IgnorePointer(
            child: AnimatedOpacity(
              opacity: show ? 0.3 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Container(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }

 
  Set<Polyline> _buildPolylines(MapState state) {
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

// ── Extracted GoogleMap widget to prevent unnecessary rebuilds ─────────────────
// By isolating GoogleMap in its own StatelessWidget, parent rebuilds caused by
// stepProvider or toast state don't force the platform view to reconstruct.



// ── Supporting widgets ─────────────────────────────────────────────────────────

class _TerritoryLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: Color(0xFF7B6FD4), label: 'Yours'),
          SizedBox(height: 8),
          _LegendItem(color: Color(0xFFEF4444), label: 'Enemy'),
          SizedBox(height: 8),
          _LegendItem(color: Color(0xFF3B82F6), label: 'Protected'),
          SizedBox(height: 8),
          _LegendItem(color: Color(0xFFA855F7), label: 'Weakened'),
          SizedBox(height: 8),
          _LegendItem(color: Color(0xFFF1F5F9), label: 'Neutral'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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