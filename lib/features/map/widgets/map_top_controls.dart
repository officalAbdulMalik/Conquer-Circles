import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/features/profile/view/profile_bottom_sheet.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/widgets/shared/app_bar_icon_tile.dart';

class MapTopControls extends StatelessWidget {
  const MapTopControls({
    super.key,
    required this.onBack,
    required this.onLocate,
  });

  final VoidCallback onBack;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 50.sp,
          left: 16.sp,
          child: _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
        ),
        Positioned(
          top: 50.sp,
          right: 62.sp,
          child: DashboardIconButton(
            icon: 'assets/icons/notification.png',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ),
        Positioned(
          top: 50.sp,
          right: 16.sp,
          child: DashboardIconButton(
            icon: 'assets/icons/profile.png',
            onTap: () => showProfileBottomSheet(context),
          ),
        ),
        Positioned(
          top: 120.sp,
          right: 26.sp,
          child: _LocateTargetButton(onTap: onLocate),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 21.sp),
      ),
    );
  }
}

class _LocateTargetButton extends StatelessWidget {
  const _LocateTargetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32.w,
        height: 32.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 16.w, height: 2, color: Colors.black),
            Container(width: 2, height: 16.w, color: Colors.black),
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
