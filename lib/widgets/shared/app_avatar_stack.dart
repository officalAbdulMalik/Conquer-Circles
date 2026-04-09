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
                border: Border.all(color: AppColors.surface, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4.r,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  emojis[index],
                  style: TextStyle(fontSize: (size * 0.46).sp),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
