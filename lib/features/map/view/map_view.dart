import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/features/map/widgets/exit_run_dialog.dart';
import 'package:test_steps/features/map/widgets/hex_grid_overlay.dart';
import 'package:test_steps/features/map/widgets/home_base_setup_sheet.dart';
import 'package:test_steps/features/map/widgets/map_top_controls.dart';
import 'package:test_steps/features/map/widgets/run_session_summary_panel.dart';
import 'package:test_steps/features/map/widgets/tile_info_sheet.dart';
import 'package:test_steps/models/map_model.dart';
import 'package:test_steps/models/walk_models.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/widgets/shared/map_view.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

enum _MapDesignStep { start, homeBase, tracking, paused }

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? _mapController;
  final Set<Polygon> _hexGrid = {};

  _MapDesignStep _step = _MapDesignStep.start;
  DateTime? _trackingStartedAt;
  DateTime? _trackingPausedAt;
  bool _showExitRunDialog = false;
  bool _showStartTerritories = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final currentUserId = ref.read(mapProvider.notifier).currentUser?.id;
    final mapCenter =
        mapState.userLocation ??
        mapState.homeBase ??
        const LatLng(31.5204, 74.3587);
    final territoryPolygons = HexGridOverlay.build(
      mapState.nearbyTerritories,
      currentUserId,
      homeBase: mapState.homeBase,
      mapCenter: mapCenter,
      onTerritoryTap: (territory) {
        if (_isOwnTerritory(territory, currentUserId)) {
          _showOwnedTerritorySheet(territory);
        }
      },
    );

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMapLayer(
              hexGrid: _hexGrid,
              hexPolygons: territoryPolygons,
              mapState: mapState,
              onMapCreated: (controller) => _mapController = controller,
              onCameraIdle: () async {
                final bounds = await _mapController?.getVisibleRegion();
                if (bounds != null) {
                  ref
                      .read(mapProvider.notifier)
                      .loadTerritoriesForBounds(bounds);
                }
              },
              onCameraMove: (_) {},
              onTap: (_) => _showOwnedTerritorySheet(
                _testingOwnedTerritory(mapState, currentUserId),
              ),
              buildPolylines: () => const <Polyline>{},
            ),
            MapTopControls(
              onBack: () => Navigator.maybePop(context),
              onLocate: () => _focusLocation(mapState),
            ),
            if (_step != _MapDesignStep.homeBase) _buildBottomOverlay(),
            if (_step == _MapDesignStep.homeBase) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _step = _MapDesignStep.start),
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),
              HomeBaseSetupSheet(
                isLoading: false,
                // Design-only: no location, RPC, or provider calls.
                onUseCurrentLocation: () {},
                onSetHomeBase: _showTrackingSummary,
              ),
            ],
            if (_showExitRunDialog) ...[
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
              ExitRunDialog(
                onClose: () => setState(() => _showExitRunDialog = false),
                onConfirmExit: _confirmFinishRun,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    if (_step == _MapDesignStep.tracking || _step == _MapDesignStep.paused) {
      return Positioned.fill(
        child: RunSessionSummaryPanel(
          startedAt: _trackingStartedAt,
          pausedAt: _trackingPausedAt,
          distanceKm: 0,
          totalAreaKm2: 0,
          isPaused: _step == _MapDesignStep.paused,
          onPause: _pauseTrackingSummary,
          onResume: _resumeTrackingSummary,
          onFinish: () => setState(() => _showExitRunDialog = true),
        ),
      );
    }

    return _buildStartTerritoriesSheet();
  }

  Widget _buildStartTerritoriesSheet() {
    final territories = _startSheetTerritories(
      ref.read(mapProvider),
      ref.read(mapProvider.notifier).currentUser?.id,
    );

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _handleStartSheetNotification,
      child: DraggableScrollableSheet(
        initialChildSize: 0.13,
        minChildSize: 0.13,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.13, 0.92],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 49,
                            height: 5,
                            margin: EdgeInsets.only(
                              bottom: _showStartTerritories ? 8 : 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9DCE4),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          if (!_showStartTerritories)
                            PrimaryButton(
                              label: 'Tap to Start',
                              onTap: _showHomeBaseSetup,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        return OwnedTerritoryInfoCard(
                          territory: territories[index],
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemCount: _showStartTerritories ? territories.length : 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHomeBaseSetup() {
    setState(() {
      _showStartTerritories = false;
      _step = _MapDesignStep.homeBase;
    });
  }

  bool _handleStartSheetNotification(
    DraggableScrollableNotification notification,
  ) {
    final shouldShow = notification.extent > 0.14;
    if (shouldShow == _showStartTerritories) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && shouldShow != _showStartTerritories) {
        setState(() => _showStartTerritories = shouldShow);
      }
    });

    return false;
  }

  List<Territory> _startSheetTerritories(
    MapState mapState,
    String? currentUserId,
  ) {
    final territories = _trackingSheetTerritories(mapState, currentUserId);
    var previewIndex = 0;

    while (territories.length < 3) {
      previewIndex += 1;
      final source = territories.isEmpty
          ? _testingOwnedTerritory(mapState, currentUserId)
          : territories.first;
      territories.add(
        source.copyWith(
          id: '${source.id}-start-preview-$previewIndex',
          energy: (source.energy + previewIndex * 5).clamp(15, 60),
          lastActivityTime: DateTime.now().subtract(
            Duration(minutes: 20 + previewIndex * 8),
          ),
        ),
      );
    }

    return territories;
  }

  void _showTrackingSummary() {
    setState(() {
      _step = _MapDesignStep.tracking;
      _trackingStartedAt = DateTime.now();
      _trackingPausedAt = null;
    });
  }

  void _pauseTrackingSummary() {
    setState(() {
      _step = _MapDesignStep.paused;
      _trackingPausedAt = DateTime.now();
    });
  }

  void _resumeTrackingSummary() {
    final startedAt = _trackingStartedAt;
    final pausedAt = _trackingPausedAt;
    final elapsedBeforePause = startedAt == null || pausedAt == null
        ? Duration.zero
        : pausedAt.difference(startedAt);

    setState(() {
      _step = _MapDesignStep.tracking;
      _trackingStartedAt = DateTime.now().subtract(elapsedBeforePause);
      _trackingPausedAt = null;
    });
  }

  void _confirmFinishRun() {
    setState(() {
      _showExitRunDialog = false;
      _showStartTerritories = false;
      _step = _MapDesignStep.start;
      _trackingStartedAt = null;
      _trackingPausedAt = null;
    });
  }

  void _focusLocation(MapState mapState) {
    final loc = mapState.userLocation ?? mapState.homeBase;
    if (loc != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
    }
  }

  bool _isOwnTerritory(Territory territory, String? currentUserId) {
    return currentUserId != null && territory.userId == currentUserId;
  }

  List<Territory> _trackingSheetTerritories(
    MapState mapState,
    String? currentUserId,
  ) {
    final ownedTerritories = mapState.nearbyTerritories
        .where((territory) => _isOwnTerritory(territory, currentUserId))
        .toList();

    if (ownedTerritories.isNotEmpty) {
      return ownedTerritories;
    }

    return [_testingOwnedTerritory(mapState, currentUserId)];
  }

  void _showOwnedTerritorySheet(Territory territory) {
    final mapState = ref.read(mapProvider);
    final currentUserId = ref.read(mapProvider.notifier).currentUser?.id;

    showOwnedTerritoryInfoSheet(
      context: context,
      territory: territory,
      territories: _trackingSheetTerritories(mapState, currentUserId),
    );
  }

  Territory _testingOwnedTerritory(MapState mapState, String? currentUserId) {
    Territory? ownedTerritory;
    for (final territory in mapState.nearbyTerritories) {
      if (_isOwnTerritory(territory, currentUserId)) {
        ownedTerritory = territory;
        break;
      }
    }

    if (ownedTerritory != null) return ownedTerritory;

    final existingTerritory = mapState.nearbyTerritories.isEmpty
        ? null
        : mapState.nearbyTerritories.first;
    final base =
        existingTerritory ??
        Territory(
          id: 'testing-owned-territory',
          userId: currentUserId ?? 'testing-user',
          username: 'Aqib Javid',
          color: '#5169FF',
          energy: 45,
          captureTime: DateTime(2026, 5, 16, 20, 42),
          lastActivityTime: DateTime.now().subtract(
            const Duration(minutes: 20),
          ),
        );

    return base.copyWith(
      userId: currentUserId ?? base.userId,
      username: base.username == 'Unknown' ? 'Aqib Javid' : base.username,
      energy: base.energy == 0 ? 45 : base.energy,
      captureTime: base.captureTime ?? DateTime(2026, 5, 16, 20, 42),
      lastActivityTime:
          base.lastActivityTime ??
          DateTime.now().subtract(const Duration(minutes: 20)),
    );
  }
}
