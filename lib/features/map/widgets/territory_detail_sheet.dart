import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/tile_handler.dart';

class TerritoryDetailSheet extends StatelessWidget {
  final MapTile tile;
  final String? currentUserId;
  final VoidCallback? onClaim;
  final VoidCallback? onActivateShield;

  const TerritoryDetailSheet({
    super.key,
    required this.tile,
    this.currentUserId,
    this.onClaim,
    this.onActivateShield,
  });

  static Future<void> show(
    BuildContext context, {
    required MapTile tile,
    String? currentUserId,
    VoidCallback? onClaim,
    VoidCallback? onActivateShield,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TerritoryDetailSheet(
        tile: tile,
        currentUserId: currentUserId,
        onClaim: onClaim,
        onActivateShield: onActivateShield,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMine = tile.ownerId == currentUserId;
    final int energyPercent = (tile.energy / 60.0 * 100).toInt().clamp(0, 100);
    final String lastVisit = _formatRelativeTime(DateTime.now().subtract(const Duration(minutes: 2))); // Mock data for now
    final String shieldTime = tile.isProtected ? '42min' : 'None'; // Mock data for now

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.ownerUsername ?? 'Territory ${tile.tileId.substring(0, 6)}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tile.isProtected ? 'Protected Zone' : 'Standard Zone',
                            style: TextStyle(
                              color: const Color(0xFF6366F1),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isMine) ...[
                          SizedBox(width: 8.w),
                          Text(
                            '· You',
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 20.sp, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zone Energy',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$energyPercent%',
                style: TextStyle(
                  color: const Color(0xFF0D9488),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: energyPercent / 100,
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF2DD4BF)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  icon: Icons.architecture_rounded,
                  value: '~2.1km²',
                  label: 'Area',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _DetailCard(
                  icon: Icons.access_time_filled_rounded,
                  value: lastVisit,
                  label: 'Last Visit',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _DetailCard(
                  icon: Icons.shield_rounded,
                  value: shieldTime,
                  label: 'Shield Left',
                  iconColor: const Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
          if (tile.isProtected) ...[
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCFBF1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 20),
                  SizedBox(width: 12.w),
                  Text(
                    'Shield active · expires in 42 min',
                    style: TextStyle(
                      color: const Color(0xFF0D9488),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    return '2m ago';
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _DetailCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? const Color(0xFF94A3B8), size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
