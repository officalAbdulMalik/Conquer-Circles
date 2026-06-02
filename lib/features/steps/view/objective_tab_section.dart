import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/widgets/objective_card.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class ObjectiveEnergyHeader extends StatelessWidget {
  const ObjectiveEnergyHeader({
    super.key,
    this.energy = 265,
    this.targetEnergy = 300,
    this.level = 15,
    this.progress = 0.63,
  });

  final int energy;
  final int targetEnergy;
  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: AppColors.blueContiner,
        borderRadius: BorderRadius.circular(24.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'FitWarrior',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 16.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Level $level',
                        style: AppTextStyles.montserrat(
                          size: 12.sp,
                          color: AppColors.blueColor,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
                Text(
                  '$energy / $targetEnergy Energy',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w400,
                  ),
                ),
                8.verticalSpace,
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        Container(
                          width: constraints.maxWidth * normalizedProgress,
                          height: 5.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8C70F8), Color(0xFF53E4F3)],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          Text(
            '${(normalizedProgress * 100).round()}%',
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectiveTabSection extends StatelessWidget {
  const ObjectiveTabSection({
    super.key,
    required this.steps,
    this.onObjectiveTap,
  });

  final int steps;
  final VoidCallback? onObjectiveTap;

  @override
  Widget build(BuildContext context) {
    final safeSteps = steps <= 0 ? 6420 : steps;
    final stepsPercent = steps <= 0 ? 0.78 : (safeSteps / 8000).clamp(0.0, 1.0);

    return Column(
      children: [
        ObjectiveTaskCard(
          icon: 'assets/icons/battery.svg',
          title: 'Capture 5 New Tiles',
          progressLabel: 'Progress: 3 / 5',
          percent: 0.63,
          iconColor: const Color(0xFF5397FF),
          iconBackgroundColor: const Color(0xFFD8E9FF),
          onTap: onObjectiveTap,
        ),
        12.verticalSpace,
        ObjectiveTaskCard(
          icon: 'assets/icons/battery.svg',
          title: 'Walk 8,000 Steps',
          progressLabel: '${_formatCount(safeSteps)} / 8,000',
          percent: stepsPercent,
          iconColor: const Color(0xFF5397FF),
          iconBackgroundColor: const Color(0xFFD8E9FF),
          onTap: onObjectiveTap,
        ),
      ],
    );
  }
}


String _formatCount(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}
