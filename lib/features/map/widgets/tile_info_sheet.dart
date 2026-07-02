import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

import '../../../models/walk_models.dart';
import '../../../providers/map_provider.dart';
import 'attack_toast.dart';

void showOwnedTerritoryInfoSheet({
  required BuildContext context,
  required Territory territory,
  List<Territory> territories = const [],
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _OwnedTerritoryInfoSheet(
      territory: territory,
      territories: territories,
    ),
  );
}

class _OwnedTerritoryInfoSheet extends StatelessWidget {
  final Territory territory;
  final List<Territory> territories;

  const _OwnedTerritoryInfoSheet({
    required this.territory,
    required this.territories,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final sheetTerritories = _sheetTerritories;

    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.40, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.sp)),
            border: AppBorders.raised(),
          ),
          child: SafeArea(
            top: false,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 49,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9DCE4),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      return OwnedTerritoryInfoCard(
                        territory: sheetTerritories[index],
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemCount: sheetTerritories.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Territory> get _sheetTerritories {
    final seenIds = <String>{territory.id};
    return [
      territory,
      for (final item in territories)
        if (seenIds.add(item.id)) item,
    ];
  }
}

class OwnedTerritoryInfoCard extends StatelessWidget {
  const OwnedTerritoryInfoCard({super.key, required this.territory});

  final Territory territory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: AppBorders.raised(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(painter: _TerritoryMapPreviewPainter()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Territory Captured',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          color: AppColors.textPrimary,
                          size: 16.sp,
                          height: 1.15,
                          weight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          color: AppColors.textPrimary,
                          size: 14.sp,
                          height: 1.2,
                          weight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Energy ${territory.energy.clamp(0, 60)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          color: AppColors.textPrimary,
                          size: 14.sp,
                          height: 1.15,
                          weight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _capturedAtLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          color: AppColors.textSecondary,
                          size: 12.sp,
                          height: 1.15,
                          weight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TerritoryInfoMetric(
                  icon: Icons.calendar_month,
                  iconColor: const Color(0xFF5169FF),
                  iconBgColor: const Color(0xFFEAF1FF),
                  label: 'Capture time',
                  value: _captureAgeLabel,
                ),
              ),
              Expanded(
                child: _TerritoryInfoMetric(
                  icon: Icons.directions_run,
                  iconColor: const Color(0xFF3B82F6),
                  iconBgColor: const Color(0xFFEAF1FF),
                  label: 'Last Visit',
                  value: _lastVisitLabel,
                ),
              ),
              Expanded(
                child: _TerritoryInfoMetric(
                  icon: Icons.bolt,
                  iconColor: Colors.white,
                  iconBgColor: const Color(0xFF25D83B),
                  label: 'Energy',
                  value: '${territory.energy.clamp(0, 60)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _displayName {
    return territory.username.trim().isEmpty || territory.username == 'Unknown'
        ? 'Unknown owner'
        : territory.username;
  }

  String get _capturedAtLabel {
    final capturedAt = territory.captureTime;
    if (capturedAt == null) return 'Capture time unavailable';
    return '${_weekday(capturedAt)} ${capturedAt.day} ${_month(capturedAt)} · ${_time(capturedAt)}';
  }

  String get _captureAgeLabel {
    final capturedAt = territory.captureTime;
    if (capturedAt == null) return 'Unknown';
    final days = DateTime.now().difference(capturedAt).inDays;
    if (days <= 0) return 'Today';
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  String get _lastVisitLabel {
    final lastVisit = territory.lastActivityTime;
    if (lastVisit == null) return 'Unknown';
    final minutes = DateTime.now().difference(lastVisit).inMinutes;
    if (minutes < 60) return '${minutes.clamp(1, 59)} min';
    final hours = DateTime.now().difference(lastVisit).inHours;
    return '$hours ${hours == 1 ? 'hr' : 'hrs'}';
  }

  String _weekday(DateTime value) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[value.weekday - 1];
  }

  String _month(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[value.month - 1];
  }

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _TerritoryMapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF3F5F9), BlendMode.src);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final roadShadow = Paint()
      ..color = const Color(0xFFD9DEE8)
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final roads = [
      [Offset(-8, 18), Offset(size.width * 0.92, size.height * 0.10)],
      [Offset(size.width * 0.18, -8), Offset(size.width * 0.45, size.height)],
      [Offset(size.width * 0.74, -6), Offset(size.width * 0.86, size.height)],
      [Offset(-8, size.height * 0.68), Offset(size.width, size.height * 0.52)],
    ];

    for (final road in roads) {
      canvas.drawLine(road[0], road[1], roadShadow);
      canvas.drawLine(road[0], road[1], roadPaint);
    }

    final blockPaint = Paint()..color = const Color(0xFFD7DDE7);
    final blocks = [
      Rect.fromLTWH(6, 8, 18, 24),
      Rect.fromLTWH(33, 6, 22, 18),
      Rect.fromLTWH(64, 14, 24, 28),
      Rect.fromLTWH(10, 48, 24, 17),
      Rect.fromLTWH(44, 42, 18, 27),
      Rect.fromLTWH(68, 60, 22, 24),
    ];
    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(block, const Radius.circular(3)),
        blockPaint,
      );
    }

    final territoryPath = Path()
      ..moveTo(size.width * 0.46, size.height * 0.12)
      ..lineTo(size.width * 0.24, size.height * 0.28)
      ..lineTo(size.width * 0.35, size.height * 0.82)
      ..lineTo(size.width * 0.78, size.height * 0.88)
      ..lineTo(size.width * 0.88, size.height * 0.38)
      ..lineTo(size.width * 0.54, size.height * 0.30)
      ..close();

    canvas.drawPath(
      territoryPath,
      Paint()..color = const Color(0xFF5169FF).withValues(alpha: 0.10),
    );
    canvas.drawPath(
      territoryPath,
      Paint()
        ..color = const Color(0xFF5169FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final markerCenter = Offset(size.width * 0.28, size.height * 0.30);
    canvas.drawCircle(markerCenter, 5, Paint()..color = Colors.white);
    canvas.drawCircle(
      markerCenter,
      3.5,
      Paint()..color = const Color(0xFF111827),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TerritoryInfoMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;

  const _TerritoryInfoMetric({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(
            color: AppColors.textPrimary,
            size: 14.sp,
            weight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 15,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tile Info Bottom Sheet
// ---------------------------------------------------------------------------

/// Shows info about a tapped territory and optionally an Attack / Claim button.
///
/// Pass [tile] for a claimed territory, or null for an unclaimed area.
void showTileInfoSheet({
  required BuildContext context,
  required Territory? tile,
  required String? currentUserId,
  required AttackToastController toastController,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TileInfoSheet(
      tile: tile,
      currentUserId: currentUserId,
      toastController: toastController,
    ),
  );
}

class _TileInfoSheet extends ConsumerStatefulWidget {
  final Territory? tile;
  final String? currentUserId;
  final AttackToastController toastController;

  const _TileInfoSheet({
    required this.tile,
    required this.currentUserId,
    required this.toastController,
  });

  @override
  ConsumerState<_TileInfoSheet> createState() => _TileInfoSheetState();
}

class _TileInfoSheetState extends ConsumerState<_TileInfoSheet> {
  /// Action-in-flight flag; ValueNotifier so only the content panel rebuilds.
  final ValueNotifier<bool> _loading = ValueNotifier(false);

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  bool get _isOwn => widget.tile?.userId == widget.currentUserId;
  bool get _isNeutral => widget.tile == null || widget.tile!.userId.isEmpty;
  bool get _isProtected => widget.tile?.isProtected() ?? false;
  bool get _isInCooldown {
    final cooldownUntil = widget.tile?.cooldownUntil;
    return cooldownUntil != null && cooldownUntil.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final territory = widget.tile;

    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ValueListenableBuilder<bool>(
                valueListenable: _loading,
                builder: (context, loading, _) => _isNeutral
                    ? _NeutralTileContent(
                        onClaim: _handleClaim,
                        loading: loading,
                      )
                    : _isOwn
                    ? _OwnTileContent(
                        territory: territory!,
                        onReinforce: _handleAttack,
                        loading: loading,
                      )
                    : _EnemyTileContent(
                        territory: territory!,
                        onAttack: _handleAttack,
                        loading: loading,
                        isProtected: _isProtected,
                        isInCooldown: _isInCooldown,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAttack() async {
    if (widget.tile == null) return;
    _loading.value = true;

    final result = await ref
        .read(mapProvider.notifier)
        .onEnterTerritory(widget.tile!.id);

    if (!mounted) return;
    _loading.value = false;

    if (result != null) Navigator.pop(context);
  }

  Future<void> _handleClaim() async {
    _loading.value = true;
    final loc = ref.read(mapProvider).userLocation;
    if (loc == null) {
      _loading.value = false;
      return;
    }

    if (widget.tile != null) {
      final result = await ref
          .read(mapProvider.notifier)
          .onEnterTerritory(widget.tile!.id);
      if (!mounted) return;
      _loading.value = false;
      if (result != null) Navigator.pop(context);
      return;
    }

    widget.toastController.show(
      AttackToastVariant.claimed,
      'Move into a highlighted territory to claim it.',
    );
    if (mounted) {
      _loading.value = false;
      Navigator.pop(context);
    }
  }
}

// ---------------------------------------------------------------------------
// Content panels
// ---------------------------------------------------------------------------

class _OwnTileContent extends StatelessWidget {
  final Territory territory;
  final VoidCallback onReinforce;
  final bool loading;

  const _OwnTileContent({
    required this.territory,
    required this.onReinforce,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final protected = territory.isProtected();
    final shieldEnd = territory.shieldUntil ?? territory.protectedUntil;
    final cooldownUntil = territory.cooldownUntil;
    final isInCooldown =
        cooldownUntil != null && cooldownUntil.isAfter(DateTime.now());
    final energy = territory.energy.clamp(0, 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.flag, color: Color(0xFF2196F3), size: 18),
            const SizedBox(width: 8),
            const Text(
              'Your Territory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Energy bar
        _EnergyBar(current: energy, max: 60, color: const Color(0xFF2196F3)),
        const SizedBox(height: 12),

        // Shield status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: protected
                ? const Color(0xFF9C27B0).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: protected
                  ? const Color(0xFF9C27B0).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                protected ? Icons.shield : Icons.shield_outlined,
                color: protected
                    ? const Color(0xFF9C27B0)
                    : const Color(0xFF757575),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                protected && shieldEnd != null
                    ? 'Protected for ${_formatRemaining(shieldEnd)}'
                    : 'Unprotected',
                style: TextStyle(
                  color: protected
                      ? const Color(0xFF9C27B0)
                      : const Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (territory.lastActivityTime != null)
          Text(
            'Last active ${_timeAgo(territory.lastActivityTime!)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        if (isInCooldown) ...[
          const SizedBox(height: 8),
          _CooldownStatusPill(until: cooldownUntil),
        ],

        const Spacer(),

        // Reinforce button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: energy < 60 && !loading ? onReinforce : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              side: const BorderSide(color: Color(0xFF2196F3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline, size: 16),
            label: Text(
              loading ? 'Reinforcing...' : 'Reinforce',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _formatRemaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return 'yesterday';
  }
}

class _EnemyTileContent extends StatelessWidget {
  final Territory territory;
  final VoidCallback onAttack;
  final bool loading;
  final bool isProtected;
  final bool isInCooldown;
  const _EnemyTileContent({
    required this.territory,
    required this.onAttack,
    required this.loading,
    required this.isProtected,
    required this.isInCooldown,
  });

  @override
  Widget build(BuildContext context) {
    final energy = territory.energy.clamp(0, 60);
    final color = _hexColor(territory.color);
    final shieldEnd = territory.shieldUntil ?? territory.protectedUntil;
    final cooldownUntil = territory.cooldownUntil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person, color: Color(0xFFFF5722), size: 18),
            const SizedBox(width: 8),
            Text(
              territory.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _EnergyBar(current: energy, max: 60, color: color),
        const SizedBox(height: 12),

        if (isInCooldown && cooldownUntil != null)
          _CooldownStatusPill(until: cooldownUntil)
        else
          const Row(
            children: [
              Icon(Icons.bolt, color: Color(0xFFFF9800), size: 14),
              SizedBox(width: 4),
              Text(
                'Your energy is shown on the map',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),

        const Spacer(),

        // Attack button — disabled if protected, cooling down, or loading
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (isProtected || isInCooldown || loading)
                ? null
                : onAttack,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInCooldown
                  ? const Color(0xFFF59E0B)
                  : isProtected
                  ? const Color(0xFF9C27B0)
                  : const Color(0xFFF44336),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isInCooldown
                        ? Icons.timer_outlined
                        : isProtected
                        ? Icons.shield
                        : Icons.flash_on,
                    size: 16,
                  ),
            label: Text(
              isInCooldown && cooldownUntil != null
                  ? 'Cooldown: ${_remaining(cooldownUntil)}'
                  : isProtected && shieldEnd != null
                  ? 'Protected: ${_remaining(shieldEnd)}'
                  : 'Attack',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _remaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF0D968B);
    }
  }
}

class _CooldownStatusPill extends StatelessWidget {
  const _CooldownStatusPill({required this.until});

  final DateTime until;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 14),
          const SizedBox(width: 6),
          Text(
            'Cooldown ${_formatCooldownRemaining(until)}',
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCooldownRemaining(DateTime end) {
  final diff = end.difference(DateTime.now());
  if (diff.isNegative) return 'expired';
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  final seconds = diff.inSeconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

class _NeutralTileContent extends StatelessWidget {
  final VoidCallback onClaim;
  final bool loading;
  const _NeutralTileContent({required this.onClaim, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unclaimed Territory',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _EnergyBar(current: 0, max: 60, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 8),
        Text(
          'Walk into this territory at 2–15 km/h to claim it.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.flag, size: 16),
            label: const Text(
              'Claim',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _EnergyBar extends StatelessWidget {
  final int current;
  final int max;
  final Color color;
  const _EnergyBar({
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TILE ENERGY',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$current / $max',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
