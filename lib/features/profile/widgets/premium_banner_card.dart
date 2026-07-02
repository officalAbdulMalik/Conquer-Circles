import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class PremiumBannerCard extends StatelessWidget {
  const PremiumBannerCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.r,vertical: 12.r),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: AppColors.splashBlueDeep,
         
        ),
        child: Stack(
          children: [
            // Positioned.fill(child: Image.asset('assets/images/back.png', fit: BoxFit.contain)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Conquer Circles',
                      style: AppTextStyles.montserrat(
                        size: 18.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/icons/plus.png',
                      width: 34.w,
                      height: 34.w,
                    ),
                  ],
                ),
                10.verticalSpace,
                Text(
                  'Unlock the power of Premium',
                  style: AppTextStyles.montserrat(
                    size: 18.sp,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
                10.verticalSpace,
                PrimaryButton(
                  label: 'Try Premium',
                  onTap: onTap,
                  backgroundColor: Colors.white,
                  textStyle: AppTextStyles.montserrat(
                    size: 15.sp,
                    color: Colors.black,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadialLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.85, size.height * 0.15);
    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi * 2) / 16;
      final end = Offset(
        center.dx + math.cos(angle) * size.width,
        center.dy + math.sin(angle) * size.width,
      );
      canvas.drawLine(center, end, paint);
    }
    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(center, r * size.width * 0.18, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
