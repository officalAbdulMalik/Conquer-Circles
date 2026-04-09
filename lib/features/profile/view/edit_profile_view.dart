import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Padding(
                padding: AppSpacing.pagePadding,
                child: SingleChildScrollView(
                  
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: 'Personal Info',
                        child: Column(
                          children: const [
                            _FieldBlock(
                              label: 'Display Name',
                              hint: 'FitWarrior_92',
                              icon: Icons.person_2_outlined,
                            ),
                            _FieldBlock(
                              label: 'Username',
                              hint: '@fitwarrior',
                              icon: Icons.alternate_email,
                            ),
                            _FieldBlock(
                              label: 'Email',
                              hint: 'warrior92@email.com',
                              icon: Icons.mail_outline_rounded,
                            ),
                            _FieldBlock(
                              label: 'Location',
                              hint: 'San Francisco, CA',
                              icon: Icons.location_on_outlined,
                            ),
                            _FieldBlock(
                              label: 'Birthday',
                              hint: '',
                              icon: Icons.calendar_today_outlined,
                            ),
                            _FieldBlock(
                              label: 'Bio',
                              hint: 'Tell us about your fitness journey...',
                              icon: Icons.person_outline_rounded,
                              maxLines: 3,
                            ),
                            
                          ],
                        ),
                      ),
                      12.verticalSpace,
                      _SectionCard(
                        title: 'Body Metrics',
                        child: Row(
                          children: const [
                            Expanded(
                              child: _FieldBlock(
                                label: 'Height',
                                hint: '175',
                                icon: Icons.straighten_rounded,
                                isTight: true,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _FieldBlock(
                                label: 'Weight',
                                hint: '72',
                                icon: Icons.fitness_center_outlined,
                                isTight: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      18.verticalSpace,
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.save_alt_outlined,
                            size: 18.sp,
                            color: AppColors.surface,
                          ),
                          label: Text(
                            'Save Changes',
                            style: AppTextStyles.poppins(
                              size: 16,
                              color: AppColors.surface,
                              weight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.brandPurple,
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                        ),
                      ),
                      24.verticalSpace,
                    ],
                  ),
                ),
              ),
          
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPurple, AppColors.brandCyan],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 58.h,
            left: 14.w,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withValues(alpha: 0.18),
              ),
              child: IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.surface,
                  size: 16.sp,
                ),
              ),
            ),
          ),
          Positioned(
            top: 60.h,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Edit Profile',
                style: AppTextStyles.poppins(
                  size: 22,
                  color: AppColors.surface,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -44.h,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 98.w,
                    height: 98.w,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textNavy.withValues(alpha: 0.18),
                          blurRadius: 16.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 48.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Positioned(
                    right: -2.w,
                    bottom: -2.h,
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2.w),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 16.sp,
                        color: AppColors.surface,
                      ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppins(
              size: 18,
              color: AppColors.textNavy,
              weight: FontWeight.w700,
            ),
          ),
          10.verticalSpace,
          child,
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.isTight = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool isTight;

  @override
  Widget build(BuildContext context) {
    final double fieldHeight = maxLines > 1 ? 82.h : 44.h;
    return Padding(
      padding: EdgeInsets.only(bottom: isTight ? 0 : 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: AppColors.brandPurple),
              6.horizontalSpace,
              Text(
                label,
                style: AppTextStyles.poppins(
                  size: 12,
                  color: AppColors.brandPurple,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          6.verticalSpace,
          Container(
            width: double.infinity,
            height: fieldHeight,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.fillColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              hint,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.poppins(
                size: 14,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
