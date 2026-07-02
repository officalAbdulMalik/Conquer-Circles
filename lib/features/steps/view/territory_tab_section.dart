import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/widgets/territory_tile.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/models/walk_models.dart';
import 'package:test_steps/providers/ai_provider.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/services/dashboard_service.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_shimmer.dart';

class TerritoryTabSection extends StatelessWidget {
  const TerritoryTabSection({
    super.key,
    required this.onViewMap,
    required this.onViewTerritory,
    required this.onHistoryTap,
    required this.history,
  });

  final VoidCallback onViewMap;
  final VoidCallback onViewTerritory;
  final VoidCallback onHistoryTap;
  final List<TerritoryHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TerritoryControlCard(onViewMap: onViewMap),
        14.verticalSpace,
        _AiSuggestionCard(onViewTerritory: onViewTerritory),
        12.verticalSpace,
        Text(
          'History',
          style: AppTextStyles.montserrat(
            size: 16.sp,
            color: const Color(0xFF101623),
            weight: FontWeight.w700,
          ),
        ),
        12.verticalSpace,
        if (history.isEmpty)
          const _EmptyTerritoryHistory()
        else
          ...history.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: TerritoryHistoryCard(entry: entry, onTap: onHistoryTap),
            ),
          ),
      ],
    );
  }
}

class _EmptyTerritoryHistory extends StatelessWidget {
  const _EmptyTerritoryHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Text(
        'No territory activity yet.',
        textAlign: TextAlign.center,
        style: AppTextStyles.montserrat(
          size: 14.sp,
          color: AppColors.textSecondary,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TerritoryControlCard extends ConsumerStatefulWidget {
  const _TerritoryControlCard({required this.onViewMap});

  final VoidCallback onViewMap;

  @override
  ConsumerState<_TerritoryControlCard> createState() =>
      _TerritoryControlCardState();
}

class _TerritoryControlCardState extends ConsumerState<_TerritoryControlCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadNearbyTerritories);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final currentUserId = ref.read(mapProvider.notifier).currentUser?.id;
    final mapCenter =
        mapState.userLocation ??
        mapState.homeBase ??
        const LatLng(31.5204, 74.3587);
    final claimedCount = mapState.nearbyTerritories
        .where((territory) => territory.userId == currentUserId)
        .length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Territory Control',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(50.r),
                onTap: widget.onViewMap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 8.sp,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.r),
                    border: Border.all(color: AppColors.blueColor, width: 1.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Map',
                        style: AppTextStyles.montserrat(
                          size: 12.sp,
                          color: AppColors.blueColor,
                          weight: FontWeight.w400,
                        ),
                      ),
                      8.horizontalSpace,
                      Icon(
                        Icons.north_east_rounded,
                        size: 14.sp,
                        color: AppColors.blueColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: SizedBox(
              width: double.infinity,
              height: 360.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFE9EEF4),
                    child: CustomPaint(
                      painter: _LiveTerritoryPreviewPainter(
                        territories: mapState.nearbyTerritories,
                        currentUserId: currentUserId,
                        center: mapCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: _ClaimedTerritoryBadge(count: claimedCount),
                  ),
                  Positioned(
                    right: 12.w,
                    bottom: 12.h,
                    child: _MapLocationButton(onTap: _loadNearbyTerritories),
                  ),
                  if (mapState.isLoading)
                    const Positioned.fill(child: _TerritoryMapLoading()),
                  if (!mapState.permissionGranted &&
                      !mapState.isLoading &&
                      mapState.nearbyTerritories.isEmpty)
                    Positioned.fill(
                      child: _TerritoryMapMessage(
                        message:
                            mapState.error ??
                            'Location permission is needed to load territory and center the map.',
                        actionLabel: 'Enable',
                        onAction: () =>
                            ref.read(mapProvider.notifier).requestPermission(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          14.verticalSpace,
          const _TerritoryControlLegend(),
        ],
      ),
    );
  }

  Future<void> _loadNearbyTerritories() async {
    var location =
        ref.read(mapProvider).userLocation ?? ref.read(mapProvider).homeBase;
    if (location == null) {
      await ref.read(mapProvider.notifier).getCurrentLocation();
      location = ref.read(mapProvider).userLocation;
    }
    if (location == null) return;
    await ref.read(mapProvider.notifier).loadAllTerritories();
  }
}

class _LiveTerritoryPreviewPainter extends CustomPainter {
  const _LiveTerritoryPreviewPainter({
    required this.territories,
    required this.currentUserId,
    required this.center,
  });

  final List<Territory> territories;
  final String? currentUserId;
  final LatLng center;

  @override
  void paint(Canvas canvas, Size size) {
    _paintMapGrid(canvas, size);

    final polygonTerritories = territories
        .where((territory) => territory.polygonPoints.length >= 3)
        .toList();
    if (polygonTerritories.isEmpty) {
      _paintEmptyMapMarker(canvas, size);
      return;
    }

    final allPoints = polygonTerritories
        .expand((territory) => territory.polygonPoints)
        .toList();
    var minLat = allPoints.map((point) => point.latitude).reduce(math.min);
    var maxLat = allPoints.map((point) => point.latitude).reduce(math.max);
    var minLng = allPoints.map((point) => point.longitude).reduce(math.min);
    var maxLng = allPoints.map((point) => point.longitude).reduce(math.max);

    if ((maxLat - minLat).abs() < 0.00001) {
      minLat -= 0.0005;
      maxLat += 0.0005;
    }
    if ((maxLng - minLng).abs() < 0.00001) {
      minLng -= 0.0005;
      maxLng += 0.0005;
    }

    const padding = 20.0;
    final drawWidth = size.width - (padding * 2);
    final drawHeight = size.height - (padding * 2);

    Offset project(LatLng point) {
      final x =
          padding +
          ((point.longitude - minLng) / (maxLng - minLng)) * drawWidth;
      final y =
          padding +
          ((maxLat - point.latitude) / (maxLat - minLat)) * drawHeight;
      return Offset(x, y);
    }

    for (final territory in polygonTerritories) {
      final path = Path();
      final first = project(territory.polygonPoints.first);
      path.moveTo(first.dx, first.dy);
      for (final point in territory.polygonPoints.skip(1)) {
        final projected = project(point);
        path.lineTo(projected.dx, projected.dy);
      }
      path.close();

      final isMine = territory.userId == currentUserId;
      final isFree = territory.userId.isEmpty;
      final color = isMine
          ? const Color(0xFF7B6FD4)
          : isFree
          ? const Color(0xFFB8C2D0)
          : const Color(0xFFEF6461);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.48));
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final centerPoint = project(center);
    if (centerPoint.dx >= 0 &&
        centerPoint.dx <= size.width &&
        centerPoint.dy >= 0 &&
        centerPoint.dy <= size.height) {
      _paintLocationDot(canvas, centerPoint);
    }
  }

  void _paintMapGrid(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final minorRoadPaint = Paint()
      ..color = const Color(0xFFD6DEE8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var index = -2; index < 8; index++) {
      final y = index * 58.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 90), minorRoadPaint);
    }
    for (var index = 0; index < 6; index++) {
      final x = index * 74.0;
      canvas.drawLine(Offset(x, 0), Offset(x - 55, size.height), roadPaint);
    }
  }

  void _paintEmptyMapMarker(Canvas canvas, Size size) {
    final centerPoint = Offset(size.width / 2, size.height / 2);
    _paintLocationDot(canvas, centerPoint);
  }

  void _paintLocationDot(Canvas canvas, Offset point) {
    canvas.drawCircle(
      point,
      13,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(point, 7, Paint()..color = const Color(0xFF5169FF));
  }

  @override
  bool shouldRepaint(covariant _LiveTerritoryPreviewPainter oldDelegate) {
    return oldDelegate.territories != territories ||
        oldDelegate.currentUserId != currentUserId ||
        oldDelegate.center != center;
  }
}

class _ClaimedTerritoryBadge extends StatelessWidget {
  const _ClaimedTerritoryBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$count claimed',
        style: AppTextStyles.montserrat(
          size: 12.sp,
          color: AppColors.textPrimary,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapLocationButton extends StatelessWidget {
  const _MapLocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42.w,
          height: 42.w,
          child: Icon(
            Icons.my_location_rounded,
            size: 21.sp,
            color: AppColors.blueColor,
          ),
        ),
      ),
    );
  }
}

class _TerritoryMapLoading extends StatelessWidget {
  const _TerritoryMapLoading();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ColoredBox(color: const Color(0xFFE8EDF5).withValues(alpha: 0.7)),
    );
  }
}

class _TerritoryMapMessage extends StatelessWidget {
  const _TerritoryMapMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.montserrat(
                  size: 13.sp,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
              8.verticalSpace,
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerritoryControlLegend extends StatelessWidget {
  const _TerritoryControlLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: const [
        _TerritoryLegendItem(
          label: 'My Territory',
          indicator: _TerritoryLegendDot(color: Color(0xFF7B6FD4)),
        ),
        _TerritoryLegendItem(
          label: 'Rival Player',
          indicator: _RivalPlayerLegendDots(),
        ),
        _TerritoryLegendItem(
          label: 'Free',
          indicator: _TerritoryLegendDot(color: Color(0xFFC9D2DF)),
        ),
      ],
    );
  }
}

class _TerritoryLegendItem extends StatelessWidget {
  const _TerritoryLegendItem({required this.label, required this.indicator});

  final String label;
  final Widget indicator;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        8.horizontalSpace,
        Text(
          label,
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: AppColors.textPrimary,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _TerritoryLegendDot extends StatelessWidget {
  const _TerritoryLegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13.w,
      height: 13.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RivalPlayerLegendDots extends StatelessWidget {
  const _RivalPlayerLegendDots();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22.w,
      height: 14.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            child: _TerritoryLegendDot(color: const Color(0xFF8DA7FF)),
          ),
          Positioned(
            left: 5.w,
            child: _TerritoryLegendDot(color: const Color(0xFFFFA14A)),
          ),
          Positioned(
            left: 12.w,
            child: _TerritoryLegendDot(color: const Color(0xFFFF796F)),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionCard extends ConsumerStatefulWidget {
  const _AiSuggestionCard({required this.onViewTerritory});

  final VoidCallback onViewTerritory;

  @override
  ConsumerState<_AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends ConsumerState<_AiSuggestionCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final aiState = ref.read(aiProvider);
      if (aiState.territorySuggestion == null && !aiState.isLoadingSuggestion) {
        final stats = ref.read(dashboardProvider);
        ref.read(aiProvider.notifier).fetchTerritorySuggestion(stats);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final isLoading = aiState.isLoadingSuggestion;
    final suggestion = aiState.territorySuggestion;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xffBFDBFE)],
        ),
        border: AppBorders.raised(color: const Color(0xffBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE8ECF3)),
                ),
                child: Image.asset(
                  'assets/icons/ai.png',
                  width: 36.sp,
                  height: 36.sp,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  'AI Suggestion',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blueColor,
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    final stats = ref.read(dashboardProvider);
                    ref
                        .read(aiProvider.notifier)
                        .fetchTerritorySuggestion(stats);
                  },
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18.sp,
                    color: AppColors.blueColor,
                  ),
                ),
            ],
          ),
          8.verticalSpace,
          if (isLoading)
            _buildShimmer()
          else
            _buildContent(
              suggestion ?? 'Expand into nearby free territory to grow your zone.',
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return AppShimmer(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: Colors.white,
          border: AppBorders.raised(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF5),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            6.verticalSpace,
            Container(
              height: 15.h,
              width: 180.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF5),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            12.verticalSpace,
            Container(
              height: 13.h,
              width: 90.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF5),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String suggestion) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: widget.onViewTerritory,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: Colors.white,
          border: AppBorders.raised(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
            10.verticalSpace,
            Text(
              'View Territory',
              style: AppTextStyles.montserrat(
                size: 12.sp,
                color: AppColors.blueColor,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
