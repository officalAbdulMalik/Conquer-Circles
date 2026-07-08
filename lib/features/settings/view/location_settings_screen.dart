import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_button.dart';
import 'package:test_steps/widgets/shared/app_screen_header.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class LocationSettingsScreen extends ConsumerWidget {
  const LocationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);
    final permissionGranted = mapState.permissionGranted;
    final userLocation = mapState.userLocation;

    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(
            height: 250.h,
            color: AppColors.surface.withValues(alpha: 0.72),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 34.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppScreenHeader(title: 'Location Service'),
                  24.verticalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: AppBorders.raised(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (permissionGranted) ...[
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 72.r,
                            color: const Color(0xFF22C9A5),
                          ),
                          16.verticalSpace,
                          Text(
                            'Location Permission Granted',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.montserrat(
                              size: 16.sp,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w700,
                            ),
                          ),
                          10.verticalSpace,
                          Text(
                            'The app is successfully receiving location updates. You can walk and capture territories.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.montserrat(
                              size: 13.sp,
                              color: AppColors.textSecondary,
                              weight: FontWeight.w400,
                            ),
                          ),
                          if (userLocation != null) ...[
                            20.verticalSpace,
                            Divider(color: AppColors.borderColor, height: 1.h, thickness: 1.h),
                            20.verticalSpace,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GPS Status',
                                  style: AppTextStyles.montserrat(
                                    size: 13.sp,
                                    color: AppColors.textSecondary,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C9A5).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: AppTextStyles.montserrat(
                                      size: 11.sp,
                                      color: const Color(0xFF22C9A5),
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            12.verticalSpace,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: AppTextStyles.montserrat(
                                    size: 13.sp,
                                    color: AppColors.textSecondary,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${userLocation.latitude.toStringAsFixed(5)}, ${userLocation.longitude.toStringAsFixed(5)}',
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.montserrat(
                                      size: 13.sp,
                                      color: AppColors.textPrimary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 72.r,
                            color: Colors.orange,
                          ),
                          16.verticalSpace,
                          Text(
                            'Location Permission Required',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.montserrat(
                              size: 16.sp,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w700,
                            ),
                          ),
                          10.verticalSpace,
                          Text(
                            'We need your location permission to track your walk progress, calculate fitness statistics, and capture game territories.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.montserrat(
                              size: 13.sp,
                              color: AppColors.textSecondary,
                              weight: FontWeight.w400,
                            ),
                          ),
                          24.verticalSpace,
                          AppButton(
                            label: 'Enable Location Permission',
                            isFullWidth: true,
                            onPressed: () async {
                              await ref
                                  .read(mapProvider.notifier)
                                  .requestPermission();
                            },
                          ),
                        ],
                      ],
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
