import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/widgets/objective_card.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_shimmer.dart';

class ObjectiveEnergyHeader extends StatelessWidget {
  const ObjectiveEnergyHeader({
    super.key,
    this.username = 'User',
    this.energy = 265,
    this.targetEnergy = 400,
    this.level = 15,
    this.progress,
  });

  final String username;
  final int energy;
  final int targetEnergy;
  final int level;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final computedProgress = targetEnergy <= 0 ? 0.0 : energy / targetEnergy;
    final normalizedProgress = (progress ?? computedProgress).clamp(0.0, 1.0);

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
                        username,
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
    required this.badgeProgressObjectives,
    required this.aiGeneratedObjectives,
    this.isAiLoading = false,
  });

  final List<ObjectiveTaskData> badgeProgressObjectives;
  final List<ObjectiveTaskData> aiGeneratedObjectives;
  final bool isAiLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ObjectiveGroup(
          title: 'Badge Progress',
          subtitle: 'Milestones tied to badges you are working toward',
          objectives: badgeProgressObjectives,
          emptyText: 'No badge progress objectives yet.',
        ),
        18.verticalSpace,
        _ObjectiveGroup(
          title: 'AI Generated',
          subtitle: 'Personalized next moves from your current activity',
          objectives: aiGeneratedObjectives,
          emptyText: 'No AI objectives available yet.',
          isLoading: isAiLoading,
        ),
      ],
    );
  }
}

class ObjectiveTaskData {
  const ObjectiveTaskData({
    required this.type,
    required this.title,
    required this.progressLabel,
    required this.percent,
    this.icon = 'assets/images/battery.png',
    this.iconColor = const Color(0xFF5397FF),
    this.iconBackgroundColor = const Color(0xFFD8E9FF),
    this.onTap,
  });

  final ObjectiveTaskType type;
  final String title;
  final String progressLabel;
  final double percent;
  final String icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;
}

enum ObjectiveTaskType { badgeProgress, aiGenerated }

class _ObjectiveGroup extends StatelessWidget {
  const _ObjectiveGroup({
    required this.title,
    required this.subtitle,
    required this.objectives,
    required this.emptyText,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final List<ObjectiveTaskData> objectives;
  final String emptyText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.montserrat(
                      size: 16.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: AppTextStyles.montserrat(
                      size: 12.sp,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 14.sp,
                height: 14.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blueColor,
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: AppBorders.raised(),
                ),
                child: Text(
                  '${objectives.length}',
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: AppColors.blueColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        12.verticalSpace,
        if (isLoading)
          ..._buildSkeletonCards()
        else if (objectives.isEmpty)
          _EmptyObjectives(text: emptyText)
        else
          ...objectives.map(
            (objective) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ObjectiveTaskCard(
                icon: objective.icon,
                title: objective.title,
                progressLabel: objective.progressLabel,
                percent: objective.percent,
                iconColor: objective.iconColor,
                iconBackgroundColor: objective.iconBackgroundColor,
                onTap: objective.onTap,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSkeletonCards() {
    return List.generate(
      3,
      (i) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: AppShimmer(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: AppBorders.raised(),
            ),
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF5),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      6.verticalSpace,
                      Container(
                        height: 12.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      8.verticalSpace,
                      Container(
                        height: 5.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyObjectives extends StatelessWidget {
  const _EmptyObjectives({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Text(
        text,
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
