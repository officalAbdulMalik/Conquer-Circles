import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/auth/age_selection_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class GenderSelectionScreen extends ConsumerWidget {
  const GenderSelectionScreen({super.key});

  void _continue(BuildContext context, WidgetRef ref) {
    final result = ref.read(authProvider.notifier).completeGenderSelection();
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Please select your gender.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AgeSelectionScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(height: 260.h, color: AppColors.surface.withValues(alpha: 0.7),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppCircularBackButton(),
                  ),
                  110.verticalSpace,
                  Text(
                    "What's Your Gender?",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 24.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  30.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _GenderCard(
                          label: 'Male',
                          imagePath: 'assets/images/gender_male_avatar.png',
                          selected: authState.selectedGender == 'male',
                          onTap: () => ref
                              .read(authProvider.notifier)
                              .selectGender('male'),
                        ),
                      ),
                      14.horizontalSpace,
                      Expanded(
                        child: _GenderCard(
                          label: 'Female',
                          imagePath: 'assets/images/gender_female_avatar.png',
                          selected: authState.selectedGender == 'female',
                          onTap: () => ref
                              .read(authProvider.notifier)
                              .selectGender('female'),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Continue',
                    onTap: () => _continue(context, ref),
                  ),
                  28.verticalSpace,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.splashBlue : AppColors.borderColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 150.h,
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: AppBorders.raised(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
            10.verticalSpace,
            Text(
              label,
              style: AppTextStyles.montserrat(
                size: 16.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
