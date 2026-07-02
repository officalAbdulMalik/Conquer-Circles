import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/features/map/widgets/attack_history_sheet.dart';
import 'package:test_steps/features/map/widgets/attack_toast.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/features/map/widgets/exit_run_dialog.dart';
import 'package:test_steps/features/map/widgets/home_base_setup_sheet.dart';
import 'package:test_steps/features/map/widgets/map_top_controls.dart';
import 'package:test_steps/features/map/widgets/run_session_summary_panel.dart';
import 'package:test_steps/features/map/widgets/start_countdown_overlay.dart';
import 'package:test_steps/features/map/widgets/tile_info_sheet.dart';
import 'package:test_steps/features/map/gamified/game_map_style.dart';
import 'package:test_steps/features/map/gamified/map_attack_effect.dart';
import 'package:test_steps/features/map/gamified/player_marker_builder.dart';
import 'package:test_steps/models/map_model.dart';
import 'package:test_steps/models/walk_models.dart';
import 'package:test_steps/providers/home_base_setup_provider.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/widgets/shared/map_view.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final AttackToastController _attackToastController = AttackToastController();
  late final AnimationController _attackWarningController;

  // ── Gamified map: player marker, pulse, movement, camera follow, FX ──
  late final AnimationController _pulseController; // player glow pulse
  late final AnimationController _moveController; // smooth marker interpolation
  BitmapDescriptor? _playerIcon;
  BitmapDescriptor? _headingArrowIcon;
  BitmapDescriptor? _homeBaseIcon;
  LatLng? _playerFrom;
  LatLng? _playerTo;
  bool _followUser = true;
  bool _programmaticCameraMove = false;
  final List<MapAttackEffect> _effects = [];
  int _effectSeq = 0;

  // Player heading (degrees clockwise from north), derived in the view from
  // consecutive GPS fixes — no provider/state changes, no extra rebuilds.
  // Interpolated by the existing _moveController so rotation stays in sync
  // with the marker's positional animation.
  double _headingFrom = 0;
  double _headingTo = 0;
  bool _hasHeading = false;

  // Last camera position, written on every onCameraMove. Plain field write —
  // deliberately NOT a notifier, so tracking it never triggers a rebuild.
  CameraPosition? _lastCameraPosition;

  // Home base marker is cached and only rebuilt when its position changes.
  Marker? _cachedHomeBaseMarker;
  LatLng? _cachedHomeBasePos;

  /// Camera tilt used for the chase camera while a run is active.
  static const double _chaseTilt = 55;

  // Animation frames drive this ValueNotifier instead of setState. Only the
  // map layer and floating effect labels (wrapped in ValueListenableBuilder)
  // rebuild each frame — the rest of the screen (sheets, panels, toasts) is
  // untouched. Throttled to ~16fps so overlay diffing stays cheap.
  final ValueNotifier<int> _frameTick = ValueNotifier<int>(0);
  DateTime _lastAnimFrame = DateTime.fromMillisecondsSinceEpoch(0);
  void _bumpFrame() {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastAnimFrame).inMilliseconds < 60) return;
    _lastAnimFrame = now;
    _frameTick.value++;
  }

  // Cache of static territory polygons so per-frame animation stays cheap.
  Set<Polygon> _cachedBasePolygons = const {};
  String? _basePolygonSignature;
  StreamSubscription<NotificationEvent>? _notificationSub;
  final TextEditingController _homeBaseLocationController =
      TextEditingController();

  // Overlay visibility: ValueNotifiers so toggling an overlay rebuilds ONLY
  // the overlay subtree — never the map layer or the rest of the screen.
  // Run state (_hasStarted/_isPaused/timings) lives in mapProvider now; the
  // home-base search flow lives in homeBaseSetupProvider.
  final ValueNotifier<bool> _showHomeBaseSetup = ValueNotifier(false);
  final ValueNotifier<bool> _showStartTerritories = ValueNotifier(false);
  final ValueNotifier<bool> _showStartCountdown = ValueNotifier(false);
  final ValueNotifier<bool> _showExitRunDialog = ValueNotifier(false);
  bool _hasCenteredOnUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attackWarningController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 900),
          )
          ..addListener(() {
            if (ref.read(mapProvider).underAttackTerritoryIds.isNotEmpty) {
              _bumpFrame();
            }
          })
          ..repeat();

    // Continuously pulsing glow ring under the player marker — animates the
    // whole time the map screen is visible (TickerMode pauses it off-screen).
    _pulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1700),
        )..addListener(() {
          if (ref.read(mapProvider).userLocation != null) {
            _bumpFrame();
          }
        });
    _pulseController.repeat();

    // Interpolates the player marker smoothly between GPS fixes.
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_bumpFrame);

    // Rasterise the gamified avatar marker once we know the pixel ratio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPlayerIcon(MediaQuery.of(context).devicePixelRatio);
    });

    // Listen for in-app notifications and show attack toasts for territory events
    _notificationSub = NotificationService.notificationStream.listen((ev) {
      final variant = _variantForNotification(ev.type);
      if (variant != null) {
        final message = ev.body.isNotEmpty ? ev.body : ev.title;
        _attackToastController.show(variant, message);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSub?.cancel();
    _attackWarningController.dispose();
    _pulseController.dispose();
    _moveController.dispose();
    _frameTick.dispose();
    for (final effect in _effects) {
      effect.controller.dispose();
    }
    _effects.clear();
    _attackToastController.dispose();
    _homeBaseLocationController.dispose();
    _showHomeBaseSetup.dispose();
    _showStartTerritories.dispose();
    _showStartCountdown.dispose();
    _showExitRunDialog.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        ref.read(mapProvider).isRunActive) {
      ref.read(mapProvider.notifier).persistRunProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final currentUserId = ref.read(mapProvider.notifier).currentUser?.id;
    ref.listen<MapState>(mapProvider, (previous, next) {
      final userLocation = next.userLocation;
      if (userLocation != null && previous?.userLocation != userLocation) {
        _animatePlayerTo(userLocation);
        if (!_hasCenteredOnUser) {
          _centerMapOnUser(userLocation);
        } else if (_followUser) {
          _animateCameraToFollow(userLocation);
        }
      }

      final result = next.lastAttackResult;
      if (result == null ||
          identical(previous?.lastAttackResult, next.lastAttackResult)) {
        return;
      }
      final action = result['action']?.toString() ?? 'error';
      final variant = AttackToastController.variantFromAction(action);
      if (variant != null) {
        _attackToastController.show(variant, _attackMessage(result));
      }
      _spawnAttackEffect(next, result);
      if (_isTerritoryHistoryAction(action)) {
        ref.invalidate(attackHistoryProvider);
      }
    });

    // Home-base setup side effects: mirror the selected label into the text
    // field, surface messages, and advance the flow when the base is saved.
    ref.listen<HomeBaseSetupState>(homeBaseSetupProvider, (previous, next) {
      final label = next.selectedLabel;
      if (label != null && previous?.selectedLabel != label) {
        _homeBaseLocationController.text = label;
      }
      final message = next.message;
      if (message != null && previous?.message != message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.homeBaseSaved && previous?.homeBaseSaved != true) {
        _showHomeBaseSetup.value = false;
        _showStartCountdown.value = true;
      }
    });

    return PopScope(
      canPop: !mapState.isRunActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && ref.read(mapProvider).isRunActive) {
          _showExitRunDialog.value = true;
        }
      },
      child: Scaffold(
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Only this subtree rebuilds on animation frames (via _frameTick),
              // keeping the sheets/panels/toasts below untouched.
              ValueListenableBuilder<int>(
                valueListenable: _frameTick,
                builder: (context, _, __) {
                  final playerPos =
                      _interpolatedPlayerPos ?? mapState.userLocation;
                  return GoogleMapLayer(
                    mapState: mapState,
                    style: kGameMapStyle,
                    polygons: _buildTerritoryPolygons(mapState, currentUserId),
                    markers: _buildPlayerMarkers(mapState, playerPos),
                    circles: _buildMapCircles(mapState, playerPos),
                    showDefaultLocationDot: _playerIcon == null,
                    onCameraMoveStarted: _onCameraMoveStarted,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      final userLocation = ref.read(mapProvider).userLocation;
                      if (userLocation != null) {
                        _centerMapOnUser(userLocation);
                      }
                    },
                    onCameraIdle: () async {
                      final bounds = await _mapController?.getVisibleRegion();
                      if (bounds != null) {
                        ref
                            .read(mapProvider.notifier)
                            .loadTerritoriesForBounds(bounds);
                      }
                    },
                    // Plain field write; never rebuilds anything.
                    onCameraMove: (position) =>
                        _lastCameraPosition = position,
                    onTap: (_) => _showTerritorySheet(null, currentUserId),
                    buildPolylines: () => _buildRunPolylines(mapState),
                  );
                },
              ),
              if (mapState.isLoading &&
                  mapState.userLocation == null &&
                  mapState.homeBase == null)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0xFFF3F6FA),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              MapTopControls(
                onBack: _handleMapBack,
                onLocate: () => _focusLocation(mapState),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 145,
                child: IgnorePointer(
                  child: AttackToastOverlay(controller: _attackToastController),
                ),
              ),
              Positioned.fill(
                child: ValueListenableBuilder<int>(
                  valueListenable: _frameTick,
                  builder: (context, _, __) =>
                      Stack(children: _buildAttackHitTexts()),
                ),
              ),
              if (!mapState.isRunActive) _buildStartTerritoriesSheet(),
              if (mapState.isRunActive && mapState.runStartedAt != null)
                RunSessionSummaryPanel(
                  startedAt: mapState.runStartedAt!,
                  pausedAt: mapState.runPausedAt,
                  distanceKm: mapState.runDistanceKm,
                  steps: mapState.runSteps,
                  claimedAreaKm2: mapState.runClaimedAreaKm2,
                  isPaused: mapState.isRunPaused,
                  onPause: _pauseRun,
                  onResume: _resumeRun,
                  onFinish: _finishRun,
                  onHistory: () => showAttackHistorySheet(
                    context,
                    attackEnergy: mapState.currentAttackEnergy,
                  ),
                ),
              // Each overlay listens to its own ValueNotifier: toggling one
              // rebuilds just that subtree, never the map layer.
              ValueListenableBuilder<bool>(
                valueListenable: _showHomeBaseSetup,
                builder: (context, show, _) {
                  if (!show) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => _showHomeBaseSetup.value = false,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        // Only this Consumer rebuilds while the user types
                        // and search state changes.
                        Consumer(
                          builder: (context, ref, _) {
                            final setup = ref.watch(homeBaseSetupProvider);
                            final notifier =
                                ref.read(homeBaseSetupProvider.notifier);
                            return HomeBaseSetupSheet(
                              isLoading: setup.isSettingHomeBase,
                              isSelectingLocation: setup.isSelectingLocation,
                              isSearchingLocation: setup.isSearching,
                              locationController: _homeBaseLocationController,
                              suggestions: setup.suggestions,
                              searchError: setup.searchError,
                              onSuggestionSelected: _selectHomeBaseSuggestion,
                              onLocationChanged: notifier.onQueryChanged,
                              onSearchLocation: (query) {
                                FocusScope.of(context).unfocus();
                                notifier.search(query);
                              },
                              onUseCurrentLocation:
                                  notifier.useCurrentLocation,
                              onSetHomeBase: notifier.saveHomeBase,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _showStartCountdown,
                builder: (context, show, _) => show
                    ? StartCountdownOverlay(
                        onComplete: _completeCountdown,
                        onCancel: _cancelCountdown,
                      )
                    : const SizedBox.shrink(),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _showExitRunDialog,
                builder: (context, show, _) {
                  if (!show) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        ExitRunDialog(
                          onClose: () => _showExitRunDialog.value = false,
                          onConfirmExit: _confirmFinishRun,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              child: ValueListenableBuilder<bool>(
                valueListenable: _showStartTerritories,
                builder: (context, showTerritories, _) => CustomScrollView(
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
                                bottom: showTerritories ? 8 : 20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9DCE4),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            if (!showTerritories)
                              PrimaryButton(
                                label: 'Tap to Start',
                                onTap: _handleTapToStart,
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                      sliver: showTerritories && territories.isEmpty
                          ? const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No claimed territories are visible here yet.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : SliverList.separated(
                              itemBuilder: (context, index) {
                                return OwnedTerritoryInfoCard(
                                  territory: territories[index],
                                );
                              },
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemCount: showTerritories
                                  ? territories.length
                                  : 0,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Applies a suggestion via the provider and pans the camera to it — the
  /// only part of the home-base flow that belongs to the view.
  void _selectHomeBaseSuggestion(HomeBaseLocationSuggestion suggestion) {
    FocusScope.of(context).unfocus();
    ref.read(homeBaseSetupProvider.notifier).selectSuggestion(suggestion);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(suggestion.latitude, suggestion.longitude),
        15,
      ),
    );
  }

  bool _handleStartSheetNotification(
    DraggableScrollableNotification notification,
  ) {
    final shouldShow = notification.extent > 0.14;
    if (shouldShow == _showStartTerritories.value) return false;

    // Defer past the current layout pass; ValueNotifier only rebuilds the
    // sheet's own subtree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showStartTerritories.value = shouldShow;
    });

    return false;
  }

  List<Territory> _startSheetTerritories(
    MapState mapState,
    String? currentUserId,
  ) {
    return _trackingSheetTerritories(mapState, currentUserId);
  }

  void _handleTapToStart() {
    final mapState = ref.read(mapProvider);
    if (mapState.isLoading) return;

    if (mapState.homeBase == null) {
      ref.read(homeBaseSetupProvider.notifier).resetFlow();
      _homeBaseLocationController.clear();
      _showHomeBaseSetup.value = true;
      return;
    }

    _beginCountdown();
  }

  void _beginCountdown() {
    _showStartTerritories.value = false;
    _showStartCountdown.value = true;
  }

  void _completeCountdown() {
    if (!mounted) return;
    _showStartCountdown.value = false;
    _startRun();
  }

  void _cancelCountdown() {
    _showStartCountdown.value = false;
  }

  Future<void> _startRun() async {
    await ref.read(mapProvider.notifier).startRun();

    // Dive into the tilted chase view for the "run started" moment.
    final loc = _interpolatedPlayerPos ?? ref.read(mapProvider).userLocation;
    final controller = _mapController;
    if (loc != null && controller != null && mounted) {
      _programmaticCameraMove = true;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: loc,
            zoom: 17.5,
            tilt: _chaseTilt,
            bearing: _hasHeading ? _headingTo : 0,
          ),
        ),
      );
      Future.delayed(const Duration(milliseconds: 900), () {
        _programmaticCameraMove = false;
      });
    }
  }

  // Run lifecycle: pure delegation to mapProvider (which owns all timing);
  // the exit dialog is a local overlay notifier.
  void _pauseRun() => ref.read(mapProvider.notifier).pauseRun();

  void _resumeRun() => ref.read(mapProvider.notifier).resumeRun();

  void _finishRun() => _showExitRunDialog.value = true;

  void _handleMapBack() {
    if (ref.read(mapProvider).isRunActive) {
      _showExitRunDialog.value = true;
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _confirmFinishRun() async {
    await ref.read(mapProvider.notifier).finishRun();
    if (!mounted) return;
    _showExitRunDialog.value = false;
    _resetCameraToFlat();
  }

  Set<Polyline> _buildRunPolylines(MapState mapState) {
    // Use the faithful visual trail (captures every corner/turnaround), then
    // extend it to the live (smoothly interpolated) player position so the line
    // tracks the moving avatar in real time.
    final points = <LatLng>[...mapState.trailPoints];
    final live = _interpolatedPlayerPos;
    if (mapState.isRunActive &&
        !mapState.isRunPaused &&
        live != null &&
        (points.isEmpty || points.last != live)) {
      points.add(live);
    }

    if (points.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('active_run'),
        points: points,
        color: const Color(0xFF4169FF),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        // Above territory polygons (0–2) and the player pulse circles (3–4)
        // so the walking trail is always clearly visible.
        zIndex: 5,
      ),
    };
  }

  /// Combined territory polygons: cached static fills plus animated overlays
  /// (under-attack pulse and capture/damage flash).
  Set<Polygon> _buildTerritoryPolygons(
    MapState mapState,
    String? currentUserId,
  ) {
    return {
      ..._buildBaseTerritoryPolygons(mapState, currentUserId),
      ..._buildAnimatedTerritoryOverlays(mapState, currentUserId),
    };
  }

  Set<Polygon> _buildBaseTerritoryPolygons(
    MapState mapState,
    String? currentUserId,
  ) {
    final signature = _computeBasePolygonSignature(mapState, currentUserId);
    if (signature == _basePolygonSignature) {
      return _cachedBasePolygons;
    }

    final polygons = <Polygon>{};
    for (final territory in mapState.nearbyTerritories.where(
      (territory) => territory.userId.isNotEmpty && territory.hasPolygon,
    )) {
      final isMine = territory.userId == currentUserId;
      final baseColor = isMine
          ? const Color(0xFF4169FF)
          : _territoryColor(territory.color);
      final isProtected = territory.isProtected();

      // One Polygon per geometry part. A merged (dissolved) cluster is a
      // single part with ONE outer border — no internal borders between the
      // player's touching claims. Holes (enclaves carved out by partial
      // captures) render correctly via `holes`.
      final parts = territory.renderParts;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isEmpty) continue;
        polygons.add(
          Polygon(
            polygonId: PolygonId('claimed_${territory.id}_$i'),
            points: part.first,
            holes: part.length > 1 ? part.sublist(1) : const [],
            fillColor: baseColor.withValues(alpha: isProtected ? 0.34 : 0.24),
            strokeColor: baseColor.withValues(alpha: 0.9),
            strokeWidth: isMine ? 3 : 2,
            consumeTapEvents: true,
            onTap: () => _showTerritorySheet(territory, currentUserId),
          ),
        );
      }
    }

    _cachedBasePolygons = polygons;
    _basePolygonSignature = signature;
    return polygons;
  }

  String _computeBasePolygonSignature(
    MapState mapState,
    String? currentUserId,
  ) {
    final buffer = StringBuffer(currentUserId ?? '');
    for (final territory in mapState.nearbyTerritories) {
      if (territory.userId.isEmpty || !territory.hasPolygon) continue;
      buffer
        ..write(territory.id)
        ..write(territory.userId == currentUserId ? 'M' : 'E')
        ..write(territory.color)
        ..write(territory.isProtected() ? 'P' : '_');
      // Geometry fingerprint: part count + points per ring, so merges and
      // partial captures invalidate the cache.
      for (final part in territory.renderParts) {
        buffer.write('p');
        for (final ring in part) {
          buffer
            ..write(ring.length)
            ..write(',');
        }
      }
      buffer.write(';');
    }
    return buffer.toString();
  }

  Set<Polygon> _buildAnimatedTerritoryOverlays(
    MapState mapState,
    String? currentUserId,
  ) {
    final overlays = <Polygon>{};

    // Pulsing warning outline on territories currently under attack.
    if (mapState.underAttackTerritoryIds.isNotEmpty) {
      final warningPulse =
          (math.sin(_attackWarningController.value * math.pi * 2) + 1) / 2;
      final warningFillAlpha = 0.08 + (warningPulse * 0.16);
      final warningStrokeAlpha = 0.55 + (warningPulse * 0.45);
      final warningStrokeWidth = warningPulse > 0.5 ? 7 : 5;

      for (final territory in mapState.nearbyTerritories.where(
        (territory) =>
            territory.hasPolygon &&
            mapState.underAttackTerritoryIds.contains(territory.id),
      )) {
        final parts = territory.renderParts;
        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];
          if (part.isEmpty) continue;
          overlays.add(
            Polygon(
              polygonId: PolygonId('under_attack_${territory.id}_$i'),
              points: part.first,
              holes: part.length > 1 ? part.sublist(1) : const [],
              fillColor: const Color(
                0xFFFF2D2D,
              ).withValues(alpha: warningFillAlpha),
              strokeColor: const Color(
                0xFFFFA500,
              ).withValues(alpha: warningStrokeAlpha),
              strokeWidth: warningStrokeWidth,
              consumeTapEvents: true,
              onTap: () => _showTerritorySheet(territory, currentUserId),
              zIndex: 1,
            ),
          );
        }
      }
    }

    // Short bright flash on the territory that was just hit/captured.
    for (final effect in _effects) {
      final territoryId = effect.territoryId;
      if (territoryId == null) continue;
      final alpha = effect.territoryFlashAlpha;
      if (alpha <= 0) continue;
      final territory = _territoryById(mapState, territoryId);
      if (territory == null || !territory.hasPolygon) continue;

      final parts = territory.renderParts;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isEmpty) continue;
        overlays.add(
          Polygon(
            polygonId: PolygonId('flash_${effect.id}_$i'),
            points: part.first,
            holes: part.length > 1 ? part.sublist(1) : const [],
            fillColor: effect.color.withValues(alpha: alpha),
            strokeColor: effect.color.withValues(
              alpha: (alpha * 1.6).clamp(0.0, 0.9).toDouble(),
            ),
            strokeWidth: 4,
            zIndex: 2,
          ),
        );
      }
    }

    return overlays;
  }

  // ── Player marker, pulse, and map circles ──────────────────────────────

  Set<Marker> _buildPlayerMarkers(MapState mapState, LatLng? position) {
    final markers = <Marker>{};

    final homeMarker = _buildHomeBaseMarker(mapState.homeBase);
    if (homeMarker != null) markers.add(homeMarker);

    final icon = _playerIcon;
    if (position == null || icon == null) return markers;

    // Direction cone under the avatar: flat so it lies on the map plane and
    // rotates with the player's real-world heading.
    final arrow = _headingArrowIcon;
    if (arrow != null && _hasHeading) {
      markers.add(
        Marker(
          markerId: const MarkerId('player_heading'),
          position: position,
          icon: arrow,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: _interpolatedHeading,
          zIndex: 1,
          consumeTapEvents: false,
        ),
      );
    }

    // Avatar stays screen-upright (flat: false) so the face never tilts or
    // spins when the chase camera rotates the world underneath it.
    markers.add(
      Marker(
        markerId: const MarkerId('player'),
        position: position,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: false,
        zIndex: 2,
        consumeTapEvents: false,
      ),
    );
    return markers;
  }

  /// Home base marker, cached so the [Marker] object is only recreated when
  /// the base actually moves (per-frame calls return the cached instance).
  Marker? _buildHomeBaseMarker(LatLng? homeBase) {
    final icon = _homeBaseIcon;
    if (icon == null || homeBase == null) {
      return null;
    }
    final cached = _cachedHomeBaseMarker;
    if (cached != null && _cachedHomeBasePos == homeBase) return cached;

    _cachedHomeBasePos = homeBase;
    return _cachedHomeBaseMarker = Marker(
      markerId: const MarkerId('home_base'),
      position: homeBase,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      zIndex: 0,
      consumeTapEvents: false,
    );
  }

  Set<Circle> _buildMapCircles(MapState mapState, LatLng? position) {
    final circles = <Circle>{};

    if (position != null) {
      final value = _pulseController.value;
      final eased = Curves.easeOut.transform(value);
      const baseRadius = 5.0;
      final maxRadius = mapState.isRunActive ? 22.0 : 14.0;
      final radius = baseRadius + eased * (maxRadius - baseRadius);
      final fade = 1 - value;
      const color = Color(0xFF4169FF);

      circles
        ..add(
          Circle(
            circleId: const CircleId('player_pulse'),
            center: position,
            radius: radius,
            strokeWidth: 2,
            strokeColor: color.withValues(alpha: 0.5 * fade),
            fillColor: color.withValues(alpha: 0.12 * fade),
            zIndex: 3,
          ),
        )
        ..add(
          Circle(
            circleId: const CircleId('player_core'),
            center: position,
            radius: 3,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
            fillColor: color.withValues(alpha: 0.20),
            zIndex: 4,
          ),
        );
    }

    for (final effect in _effects) {
      circles.addAll(effect.buildRings());
    }

    return circles;
  }

  // ── Smooth movement + chase camera ─────────────────────────────────────

  LatLng? get _interpolatedPlayerPos {
    final target = _playerTo;
    if (target == null) return ref.read(mapProvider).userLocation;
    final from = _playerFrom ?? target;
    final value = Curves.easeInOut.transform(_moveController.value);
    return LatLng(
      from.latitude + (target.latitude - from.latitude) * value,
      from.longitude + (target.longitude - from.longitude) * value,
    );
  }

  /// Heading interpolated along the shortest arc, driven by the same
  /// controller as the positional animation (no extra ticker).
  double get _interpolatedHeading {
    if (!_hasHeading) return _headingTo;
    final t = Curves.easeInOut.transform(_moveController.value);
    final delta = ((_headingTo - _headingFrom + 540) % 360) - 180;
    return (_headingFrom + delta * t + 360) % 360;
  }

  void _animatePlayerTo(LatLng next) {
    final from = _interpolatedPlayerPos ?? next;
    _playerFrom = from;
    _playerTo = next;

    // Only retarget the heading on real movement (≥3 m) so GPS jitter while
    // standing still doesn't make the direction cone spin.
    if (_quickDistanceMeters(from, next) >= 3) {
      _headingFrom = _interpolatedHeading;
      _headingTo = _bearingBetween(from, next);
      _hasHeading = true;
    }

    _moveController
      ..stop()
      ..forward(from: 0);
  }

  /// Fast equirectangular distance approximation — fine at walking scale and
  /// far cheaper than a haversine per GPS fix.
  double _quickDistanceMeters(LatLng a, LatLng b) {
    const metersPerDegree = 111320.0;
    final dLat = (b.latitude - a.latitude) * metersPerDegree;
    final dLng = (b.longitude - a.longitude) *
        metersPerDegree *
        math.cos(a.latitude * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  /// Initial great-circle bearing from [a] to [b], degrees clockwise from north.
  double _bearingBetween(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  bool get _isChaseCameraActive {
    final mapState = ref.read(mapProvider);
    return mapState.isRunActive && !mapState.isRunPaused && _hasHeading;
  }

  void _animateCameraToFollow(LatLng next) {
    final controller = _mapController;
    if (controller == null) return;
    _programmaticCameraMove = true;

    // During an active run the camera tilts behind the runner and rotates to
    // their heading — a 3D chase cam. Outside runs it's a plain flat follow.
    final update = _isChaseCameraActive
        ? CameraUpdate.newCameraPosition(
            CameraPosition(
              target: next,
              zoom: _lastCameraPosition?.zoom ?? 17.5,
              tilt: _chaseTilt,
              bearing: _headingTo,
            ),
          )
        : CameraUpdate.newLatLng(next);

    controller.animateCamera(update);
    Future.delayed(const Duration(milliseconds: 900), () {
      _programmaticCameraMove = false;
    });
  }

  /// Smoothly returns the camera to a flat, north-up view (used when a run
  /// ends so the map doesn't stay tilted).
  void _resetCameraToFlat() {
    final controller = _mapController;
    if (controller == null) return;
    final target = _interpolatedPlayerPos ??
        ref.read(mapProvider).userLocation ??
        _lastCameraPosition?.target;
    if (target == null) return;
    _programmaticCameraMove = true;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: _lastCameraPosition?.zoom ?? 17.5,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      _programmaticCameraMove = false;
    });
  }

  void _onCameraMoveStarted() {
    // A non-programmatic camera move means the user panned: stop following.
    // Plain field write — nothing in the widget tree renders this flag.
    if (_programmaticCameraMove) return;
    _followUser = false;
  }

  // ── Attack effects ─────────────────────────────────────────────────────

  Future<void> _spawnAttackEffect(
    MapState mapState,
    Map<String, dynamic> result,
  ) async {
    final action = result['action']?.toString() ?? '';
    final variant = MapAttackEffect.variantFromAction(action);
    if (variant == null) return;

    final territoryId =
        (result['source_territory_id'] ?? result['territory_id'])?.toString();
    final territory = territoryId == null
        ? null
        : _territoryById(mapState, territoryId);
    final location =
        territory?.center ??
        _centroid(territory?.polygonPoints) ??
        _interpolatedPlayerPos ??
        mapState.userLocation;
    if (location == null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final effect = MapAttackEffect(
      id: 'fx${_effectSeq++}',
      location: location,
      territoryId: territory?.id,
      variant: variant,
      label: _effectLabel(variant, result),
      color: MapAttackEffect.colorFor(variant),
      controller: controller,
    );

    controller.addListener(_bumpFrame);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _effects.remove(effect);
        controller.dispose();
        if (mounted) _frameTick.value++;
      }
    });
    _effects.add(effect);

    // Capture the on-screen anchor for the floating hit-text.
    final mapController = _mapController;
    if (mapController != null) {
      try {
        final screen = await mapController.getScreenCoordinate(location);
        if (mounted) {
          final ratio = MediaQuery.of(context).devicePixelRatio;
          effect.screenAnchor = Offset(screen.x / ratio, screen.y / ratio);
        }
      } catch (_) {
        // Leave anchor null; the text simply won't render.
      }
    }

    if (mounted) _frameTick.value++;
    controller.forward();
  }

  String _effectLabel(MapEffectVariant variant, Map<String, dynamic> result) {
    switch (variant) {
      case MapEffectVariant.captured:
        return 'Captured!';
      case MapEffectVariant.claimed:
        return 'Claimed!';
      case MapEffectVariant.reinforced:
        final after =
            result['territory_energy_after'] ?? result['energy_after'];
        return after != null ? '+$after energy' : 'Reinforced';
      case MapEffectVariant.damaged:
        final before = num.tryParse(
          '${result['territory_energy_before'] ?? result['energy_before'] ?? ''}',
        );
        final after = num.tryParse(
          '${result['territory_energy_after'] ?? result['energy_after'] ?? ''}',
        );
        if (before != null && after != null) {
          final delta = (before - after).abs().round();
          return '-$delta energy';
        }
        return 'Hit!';
    }
  }

  List<Widget> _buildAttackHitTexts() {
    final widgets = <Widget>[];
    for (final effect in _effects) {
      final anchor = effect.screenAnchor;
      if (anchor == null) continue;
      final opacity = effect.textOpacity;
      if (opacity <= 0) continue;

      widgets.add(
        Positioned(
          left: anchor.dx - 90,
          top: anchor.dy - 24 - effect.textRisePixels,
          width: 180,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: effect.textScale,
                child: Center(child: _hitTextChip(effect)),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _hitTextChip(MapAttackEffect effect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: effect.color,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: effect.color.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        effect.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Territory? _territoryById(MapState mapState, String id) {
    for (final territory in mapState.nearbyTerritories) {
      if (territory.id == id) return territory;
    }
    return null;
  }

  LatLng? _centroid(List<LatLng>? points) {
    if (points == null || points.isEmpty) return null;
    var lat = 0.0;
    var lng = 0.0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  Future<void> _loadPlayerIcon(double devicePixelRatio) async {
    // All three bitmaps are rasterised once (and memoised in the builder's
    // cache); a single frame bump swaps them in together.
    final icons = await Future.wait([
      PlayerMarkerBuilder.build(devicePixelRatio: devicePixelRatio),
      PlayerMarkerBuilder.buildHeadingArrow(devicePixelRatio: devicePixelRatio),
      PlayerMarkerBuilder.buildHomeBase(devicePixelRatio: devicePixelRatio),
    ]);
    if (!mounted) return;
    _headingArrowIcon = icons[1];
    _homeBaseIcon = icons[2];
    _playerIcon = icons[0];
    // Repaint just the map layer so the markers swap in — no full rebuild.
    _frameTick.value++;
  }

  Color _territoryColor(String value) {
    final hex = value.replaceFirst('#', '');
    final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return parsed == null ? const Color(0xFF7B6FD4) : Color(parsed);
  }

  void _focusLocation(MapState mapState) {
    final loc = _interpolatedPlayerPos ?? mapState.userLocation ?? mapState.homeBase;
    if (loc != null) {
      // Re-enable the follow camera and recenter on the player. If a run is
      // active, snap straight back into the tilted chase view.
      _followUser = true;
      _programmaticCameraMove = true;
      final update = _isChaseCameraActive
          ? CameraUpdate.newCameraPosition(
              CameraPosition(
                target: loc,
                zoom: 17.5,
                tilt: _chaseTilt,
                bearing: _headingTo,
              ),
            )
          : CameraUpdate.newLatLngZoom(loc, 17.5);
      _mapController?.animateCamera(update);
      Future.delayed(const Duration(milliseconds: 900), () {
        _programmaticCameraMove = false;
      });
    }
  }

  void _centerMapOnUser(LatLng location) {
    final controller = _mapController;
    if (controller == null) return;
    _hasCenteredOnUser = true;
    _programmaticCameraMove = true;
    controller.animateCamera(CameraUpdate.newLatLngZoom(location, 17.5));
    Future.delayed(const Duration(milliseconds: 900), () {
      _programmaticCameraMove = false;
    });
  }

  bool _isOwnTerritory(Territory territory, String? currentUserId) {
    return currentUserId != null && territory.userId == currentUserId;
  }

  List<Territory> _trackingSheetTerritories(
    MapState mapState,
    String? currentUserId,
  ) {
    return mapState.nearbyTerritories
        .where((territory) => _isOwnTerritory(territory, currentUserId))
        .toList();
  }

  void _showTerritorySheet(Territory? territory, String? currentUserId) {
    final cooldownUntil = territory?.cooldownUntil;
    if (cooldownUntil != null && cooldownUntil.isAfter(DateTime.now())) {
      _attackToastController.show(
        AttackToastVariant.cooldown,
        _cooldownRemainingLabel(cooldownUntil),
      );
    }

    showTileInfoSheet(
      context: context,
      tile: territory,
      currentUserId: currentUserId,
      toastController: _attackToastController,
    );
  }

  String _attackMessage(Map<String, dynamic> result) {
    final explicitMessage = result['message']?.toString();
    if (explicitMessage != null && explicitMessage.trim().isNotEmpty) {
      return explicitMessage;
    }

    switch (result['action']?.toString()) {
      case 'claimed':
        return 'Territory claimed.';
      case 'captured':
        return 'Enemy territory captured.';
      case 'damaged':
        final before =
            result['territory_energy_before'] ?? result['energy_before'] ?? '?';
        final after =
            result['territory_energy_after'] ?? result['energy_after'] ?? '?';
        return 'Territory damaged: $before to $after energy.';
      case 'reinforced':
        final after =
            result['territory_energy_after'] ?? result['energy_after'] ?? '?';
        return 'Territory reinforced to $after energy.';
      case 'protected':
      case 'shielded':
        return 'This territory is currently protected.';
      case 'cooldown':
        final minutes = int.tryParse(result['minutes_remaining'].toString());
        if (minutes != null && minutes > 0) {
          return '$minutes minutes remaining';
        }
        final rawUntil = result['cooldown_until'];
        final until = rawUntil == null ? null : DateTime.tryParse('$rawUntil');
        if (until != null) return _cooldownRemainingLabel(until);
        return 'Cooldown active';
      case 'no_energy':
        return 'No attack energy available.';
      default:
        return 'Territory action could not be completed.';
    }
  }

  String _cooldownRemainingLabel(DateTime cooldownUntil) {
    final remaining = cooldownUntil.difference(DateTime.now());
    if (remaining.isNegative) return 'Cooldown expired';
    final minutes = remaining.inMinutes;
    if (minutes >= 1) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} remaining';
    }
    final seconds = remaining.inSeconds.clamp(0, 59);
    return '$seconds ${seconds == 1 ? 'second' : 'seconds'} remaining';
  }

  bool _isTerritoryHistoryAction(String action) {
    return action == 'claimed' ||
        action == 'captured' ||
        action == 'damaged' ||
        action == 'reinforced';
  }

  AttackToastVariant? _variantForNotification(String type) {
    switch (type) {
      case 'territory_under_attack':
        return AttackToastVariant.damaged;
      case 'territory_lost':
      case 'raid_victory':
        return AttackToastVariant.captured;
      case 'territory_defended':
      case 'territory_strengthened':
        return AttackToastVariant.reinforced;
      case 'rival_nearby':
      case 'cluster_created':
      case 'first_territory':
      case 'welcome':
        return AttackToastVariant.claimed;
      case 'raid_failed':
      case 'cluster_broken':
      case 'rival_dominating':
      case 'error':
        return AttackToastVariant.restricted;
      case 'spark':
      case 'raid_opportunity':
      case 'energy_full':
      case 'daily_summary':
      case 'season_results':
      case 'season_starting':
      case 'mid_season_reminder':
      case 'season_ending_soon':
      case 'streak_reminder':
      case 'daily_walk_reminder':
      case 'come_back':
      case 'join_circle_reminder':
        return AttackToastVariant.generic;
      case 'protected':
      case 'shielded':
        return AttackToastVariant.restricted;
      case 'cooldown':
        return AttackToastVariant.cooldown;
      case 'no_energy':
        return AttackToastVariant.noEnergy;
      default:
        return AttackToastVariant.generic;
    }
  }
}
