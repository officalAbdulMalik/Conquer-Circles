import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/auth/weight_selection_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class AgeSelectionScreen extends ConsumerWidget {
  const AgeSelectionScreen({super.key});

  static const _quickAges = [18, 20, 25, 30, 35];

  void _continue(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WeightSelectionScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAge = ref.watch(authProvider).selectedAge;
    final authNotifier = ref.read(authProvider.notifier);

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
                  130.verticalSpace,
                  Text(
                    'How Old Are You?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 24.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  30.verticalSpace,
                  _AgeStepper(
                    age: selectedAge,
                    onDecrement: authNotifier.decrementAge,
                    onIncrement: authNotifier.incrementAge,
                  ),
                  20.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _quickAges.map((age) {
                      return _QuickAgeChip(
                        age: age,
                        selected: selectedAge == age,
                        onTap: () => authNotifier.setAge(age),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Continue',
                    onTap: () => _continue(context),
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

class _AgeStepper extends StatelessWidget {
  const _AgeStepper({
    required this.age,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int age;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78.h,
      padding: EdgeInsets.symmetric(horizontal: 78.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AgeControlButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Text(
            '$age',
            style: AppTextStyles.montserrat(
              size: 24.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
          _AgeControlButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _AgeControlButton extends StatelessWidget {
  const _AgeControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: AppBorders.raised(),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22.sp),
      ),
    );
  }
}

class _QuickAgeChip extends StatelessWidget {
  const _QuickAgeChip({
    required this.age,
    required this.selected,
    required this.onTap,
  });

  final int age;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48.w,
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.splashBlue : AppColors.surface,
          shape: BoxShape.circle,
          border: AppBorders.raised(
            color: selected ? AppColors.splashBlue : AppColors.borderColor,
          ),
        ),
        child: Text(
          '$age',
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: selected ? AppColors.surface : AppColors.textPrimary,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
