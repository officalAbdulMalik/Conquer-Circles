import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class BadgeUnlockDialog extends StatelessWidget {
  const BadgeUnlockDialog({
    super.key,
    required this.title,
    required this.description,
    this.iconUrl,
    this.earnedEnergy = 50,
    this.onShareTap,
    this.onClose,
  });

  final String title;
  final String description;
  final String? iconUrl;
  final int earnedEnergy;
  final VoidCallback? onShareTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: BadgeConfettiPainter()),
          ),
        ),
        Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: AppBorders.raised(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'BADGE UNLOCK',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: onClose ?? () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.close_rounded,
                          size: 24.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                10.verticalSpace,
                BadgeHeroPanel(iconUrl: iconUrl),
                16.verticalSpace,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 20.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                10.verticalSpace,
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w400,
                  ),
                ),
                18.verticalSpace,
                BadgeEarnedEnergyCard(earnedEnergy: earnedEnergy),
                16.verticalSpace,
                Text(
                  'Share your success journey',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                14.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BadgeShareButton(
                      icon: 'assets/icons/facebook.png',
                      onTap: onShareTap,
                    ),
                    16.horizontalSpace,
                    BadgeShareButton(
                      icon: 'assets/icons/twit.png',
                      onTap: onShareTap,
                    ),
                    16.horizontalSpace,
                    BadgeShareButton(
                      icon: 'assets/icons/insta.png',
                      onTap: onShareTap,
                    ),
                    16.horizontalSpace,
                    BadgeShareButton(
                      icon: 'assets/icons/link.png',
                      onTap: onShareTap,
                    ),
                  ],
                ),
                8.verticalSpace,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BadgeHeroPanel extends StatelessWidget {
  const BadgeHeroPanel({super.key, this.iconUrl});

  /// Badge image URL from the Supabase `badges` table.
  final String? iconUrl;

  bool get _hasImage => iconUrl != null && iconUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130.h,
      decoration: BoxDecoration(
        color: const Color(0xFFDDEBFF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.58),
            ),
          ),
          if (_hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(
                iconUrl!,
                width: 90.w,
                height: 90.w,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const _BadgeHeroFallback(),
              ),
            )
          else
            const _BadgeHeroFallback(),
        ],
      ),
    );
  }
}

class _BadgeHeroFallback extends StatelessWidget {
  const _BadgeHeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 51.w,
      height: 51.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Container(
          width: 34.w,
          height: 34.w,
          decoration: const BoxDecoration(
            color: Color(0xFFFFCC00),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 21.sp,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class BadgeEarnedEnergyCard extends StatelessWidget {
  const BadgeEarnedEnergyCard({super.key, required this.earnedEnergy});

  final int earnedEnergy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.sp),
            width: 50.w,
            height: 50.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Image.asset('assets/images/battery.png'),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earned Energy',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w400,
                  ),
                ),
                5.verticalSpace,
                Text(
                  '$earnedEnergy',
                  style: AppTextStyles.montserrat(
                    size: 20.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeShareButton extends StatelessWidget {
  const BadgeShareButton({super.key, this.icon, this.label, this.onTap});

  final String? icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(
        side: BorderSide(color: AppColors.borderColor, width: 1.w),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42.w,
          height: 42.w,
          child: Center(
            child: icon != null
                ? Image.asset(icon ?? "", height: 18.sp, width: 11.sp)
                : Text(
                    label ?? '',
                    style: AppTextStyles.montserrat(
                      size: 18.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class BadgeConfettiPainter extends CustomPainter {
  const BadgeConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final colors = [
      const Color(0xFFFFCC00),
      const Color(0xFF5169FF),
      const Color(0xFFFF4E5C),
      const Color(0xFF22C55E),
      const Color(0xFFFF8A00),
      const Color(0xFF8C70F8),
      const Color(0xFF53E4F3),
    ];

    for (var i = 0; i < 95; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.56;
      final color = colors[random.nextInt(colors.length)];
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      if (i % 7 == 0) {
        paint.style = PaintingStyle.fill;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi);
        canvas.drawPath(
          badgeStarPath(size: 7 + random.nextDouble() * 5),
          paint,
        );
        canvas.restore();
      } else if (i % 5 == 0) {
        canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 2, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 3 + random.nextDouble() * 4,
              height: 8 + random.nextDouble() * 10,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      }
    }

    for (var i = 0; i < 10; i++) {
      final start = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.36,
      );
      final path = Path()..moveTo(start.dx, start.dy);
      for (var j = 1; j < 5; j++) {
        path.relativeLineTo(
          (j.isEven ? -1 : 1) * (5 + random.nextDouble() * 6),
          11 + random.nextDouble() * 8,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[random.nextInt(colors.length)]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path badgeStarPath({required double size}) {
  final path = Path();
  const points = 5;
  final outerRadius = size;
  final innerRadius = size * 0.45;

  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? outerRadius : innerRadius;
    final angle = -math.pi / 2 + i * math.pi / points;
    final point = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  return path..close();
}
