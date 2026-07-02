import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

class BadgeDetailDialog extends StatelessWidget {
  const BadgeDetailDialog({
    super.key,
    required this.title,
    required this.description,
    this.iconUrl,
    this.showProgress = false,
    this.progressLabel = '3,420 / 5,000 steps',
    this.progress = 0.72,
    this.onContinueChallenge,
  });

  final String title;
  final String description;

  /// Badge image URL from the Supabase `badges` table.
  final String? iconUrl;

  bool get _hasImage => iconUrl != null && iconUrl!.startsWith('http');

  /// Only steps badges show the linear steps progress bar.
  final bool showProgress;
  final String progressLabel;
  final double progress;
  final VoidCallback? onContinueChallenge;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return Dialog(
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
                    'BADGE DETAIL',
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
                  onTap: () => Navigator.of(context).pop(),
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
            Container(
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
                    Opacity(
                      opacity: 0.6,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0, 0, 0, 1, 0, //
                        ]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(
                            iconUrl!,
                            width: 90.w,
                            height: 90.w,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const _LockedBadgeFallback(),
                          ),
                        ),
                      ),
                    )
                  else
                    const _LockedBadgeFallback(),
                ],
              ),
            ),
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
            // The linear steps progress bar is only relevant for steps
            // badges; other categories (territory, raid, ...) hide it.
            if (showProgress) ...[
              18.verticalSpace,
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: AppBorders.raised(),
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: AppColors.borderColor,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            Container(
                              width: constraints.maxWidth * normalizedProgress,
                              height: 6.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8C70F8),
                                    Color(0xFF53E4F3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    10.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            progressLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.montserrat(
                              size: 14.sp,
                              color: AppColors.textSecondary,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ),
                        12.horizontalSpace,
                        Text(
                          '${(normalizedProgress * 100).round()}%',
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            26.verticalSpace,
            AppOutlinedButton(
              label: 'Continue Challenge',
              onPressed:
                  onContinueChallenge ?? () => Navigator.of(context).pop(),
            ),
            10.verticalSpace,
          ],
        ),
      ),
    );
  }
}

class _LockedBadgeFallback extends StatelessWidget {
  const _LockedBadgeFallback();

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
