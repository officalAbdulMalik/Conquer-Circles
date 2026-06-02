import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/widgets/territory_tile.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class TerritoryTabSection extends StatelessWidget {
  const TerritoryTabSection({
    super.key,
    required this.onViewMap,
    required this.onViewTerritory,
    required this.onHistoryTap,
  });

  final VoidCallback onViewMap;
  final VoidCallback onViewTerritory;
  final VoidCallback onHistoryTap;

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
        TerritoryHistoryCard(onTap: onHistoryTap),
        14.verticalSpace,
        TerritoryHistoryCard(onTap: onHistoryTap),
      ],
    );
  }
}

class _TerritoryControlCard extends StatelessWidget {
  const _TerritoryControlCard({required this.onViewMap});

  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context) {
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
                onTap: onViewMap,
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
                      Icon(Icons.north_east_rounded, size: 14.sp),
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
              height: 478.h,
              child: CustomPaint(painter: TerritoryMapPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({required this.onViewTerritory});

  final VoidCallback onViewTerritory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.lightBlueColor,
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xffBFDBFE)],
        ),
        border: AppBorders.raised(color: Color(0xffBFDBFE)),
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
              Text(
                'AI Suggestion',
                style: AppTextStyles.montserrat(
                  size: 14.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: onViewTerritory,
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
                    'Expand into nearby free territory',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'Northern Edge · 320m Away',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: AppColors.textNavy,
                      weight: FontWeight.w400,
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
          ),
        ],
      ),
    );
  }
}
