import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({
    super.key,
    required this.emojis,
    this.size = 30,
    this.overlap = 18,
    this.backgroundColor = AppColors.surface,
  });

  final List<String> emojis;
  final double size;
  final double overlap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final total = emojis.length;
    return SizedBox(
      height: size.h,
      width: size.w + overlap.w * (total - 1),
      child: Stack(
        children: List.generate(total, (index) {
          return Positioned(
            left: index * overlap.w,
            child: Container(
              width: size.w,
              height: size.h,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor, width: 2.w),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size.w / 2),
                child: Image.asset(
                  'assets/images/profile.png',
                  width: size.w * 0.6,
                  height: size.h * 0.6,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
