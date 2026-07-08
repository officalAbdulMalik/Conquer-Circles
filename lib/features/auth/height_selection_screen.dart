import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/auth/goals_selection_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/dashboard_segmented_tab_bar.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/scrollable_measure_selector.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class HeightSelectionScreen extends ConsumerWidget {
  const HeightSelectionScreen({super.key});

  void _continue(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GoalsSelectionScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
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
                    'Set Your Height?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 24.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  30.verticalSpace,
                  DashboardSegmentedTabBar(
                    labels: const ['cm', 'ft'],
                    selectedIndex: authState.isCmSelected ? 0 : 1,
                    onChanged: (index) =>
                        authNotifier.setHeightUnit(index == 0 ? 'cm' : 'ft'),
                    height: 36,
                  ),
                  22.verticalSpace,
                  _HeightPickerCard(
                    selectedHeight: authState.selectedHeight,
                    selectedUnit: authState.selectedHeightUnit,
                    onHeightSelected: authNotifier.setHeight,
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

class _HeightPickerCard extends StatelessWidget {
  const _HeightPickerCard({
    required this.selectedHeight,
    required this.selectedUnit,
    required this.onHeightSelected,
  });

  final int selectedHeight;
  final String selectedUnit;
  final ValueChanged<int> onHeightSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: '$selectedHeight',
              style: AppTextStyles.montserrat(
                size: 46.sp,
                color: AppColors.splashBlue,
                weight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: ' $selectedUnit',
                  style: AppTextStyles.montserrat(
                    size: 18.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          20.verticalSpace,
          Expanded(
            child: ScrollableMeasureSelector(
              minValue: 90,
              maxValue: 250,
              selectedValue: selectedHeight,
              onChanged: onHeightSelected,
            ),
          ),
        ],
      ),
    );
  }
}
