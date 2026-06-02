import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ExitRunDialog extends StatelessWidget {
  const ExitRunDialog({
    super.key,
    required this.onClose,
    required this.onConfirmExit,
  });

  final VoidCallback onClose;
  final VoidCallback onConfirmExit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360.w,
          padding: EdgeInsets.fromLTRB(22.w, 16.h, 22.w, 22.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'EXIT RUN',
                    style: AppTextStyles.poppins(
                      size: 16.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                      size: 28.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                height: 130.h,
                decoration: BoxDecoration(
                  color: AppColors.lightBlueColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.asset(
                          'assets/images/home_base_back.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.directions_run_rounded,
                      color: const Color(0xFF2563EB),
                      size: 64.sp,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Confirm Exit Run',
                style: AppTextStyles.poppins(
                  size: 22.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'You have started a run and pressed\nback button, if you exit your run will\nlost. Are you sure want to exit?',
                textAlign: TextAlign.center,
                style: AppTextStyles.montserrat(
                  size: 16.sp,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 28.h),
              GestureDetector(
                onTap: onConfirmExit,
                child: Container(
                  height: 48.h,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppColors.blueColor, width: 1.6),
                  ),
                  child: Text(
                    'Yes, Exit Run',
                    style: AppTextStyles.montserrat(
                      size: 16.sp,
                      color: AppColors.blueColor,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
