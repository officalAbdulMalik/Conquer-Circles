import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class GoalsSelectionScreen extends ConsumerStatefulWidget {
  const GoalsSelectionScreen({super.key, this.isEditMode = false});

  final bool isEditMode;

  static const _weightGoals = ['Lose Weight', 'Maintain Weight', 'Gain Weight'];
  static const _dailyStepGoals = [5000, 8000, 10000, 12000, 15000];

  @override
  ConsumerState<GoalsSelectionScreen> createState() =>
      _GoalsSelectionScreenState();
}

class _GoalsSelectionScreenState extends ConsumerState<GoalsSelectionScreen> {
  // Edit-mode draft selections: ValueNotifiers, so taps rebuild only the
  // option lists. In onboarding mode the source of truth is authProvider.
  final ValueNotifier<String> _selectedWeightGoal = ValueNotifier(
    'Lose Weight',
  );
  final ValueNotifier<int> _selectedStepsGoal = ValueNotifier(5000);
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentGoals();
      });
    }
  }

  @override
  void dispose() {
    _selectedWeightGoal.dispose();
    _selectedStepsGoal.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentGoals() async {
    await ref.read(profileProvider.notifier).loadCurrentGoals();
    if (!mounted) return;
    final profileState = ref.read(profileProvider);
    // The provider watch triggers the rebuild that clears the loader; these
    // notifiers update only the option lists.
    _isInitialized = true;
    _selectedWeightGoal.value = profileState.currentWeightGoal;
    _selectedStepsGoal.value = profileState.currentStepGoal;
  }

  Future<void> _onUpdate() async {
    try {
      await ref.read(profileProvider.notifier).updateGoals(
        weightGoal: _selectedWeightGoal.value,
        dailyStepsGoal: _selectedStepsGoal.value,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals updated successfully.'),
          backgroundColor: Color(0xFF22C9A5),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update goals: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onFinishProfile() async {
    final result = await ref.read(authProvider.notifier).saveOnboardingProfile();
    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? 'Failed to save profile.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);

    final isSaving = widget.isEditMode
        ? profileState.isGoalsLoading
        : authState.isProfileSaving;

    final isLoading =
        widget.isEditMode && profileState.isGoalsLoading && !_isInitialized;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 260.h,
              color: AppColors.surface.withValues(alpha: 0.7),
            ),
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
                   13.verticalSpace,
                  Text(
                    widget.isEditMode ? 'Update Your Goals' : 'Set Your Goals?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 24.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  32.verticalSpace,
                  if (isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _SectionTitle(label: 'Weight Goal'),
                    12.verticalSpace,
                    ListenableBuilder(
                      listenable: Listenable.merge(
                        [_selectedWeightGoal, _selectedStepsGoal],
                      ),
                      builder: (context, _) {
                        final selectedWeight = widget.isEditMode
                            ? _selectedWeightGoal.value
                            : authState.selectedWeightGoal;
                        final selectedSteps = widget.isEditMode
                            ? _selectedStepsGoal.value
                            : authState.selectedDailyStepsGoal;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...GoalsSelectionScreen._weightGoals.map((goal) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 18.h),
                                child: _WeightGoalOption(
                                  label: goal,
                                  selected: selectedWeight == goal,
                                  onTap: () {
                                    if (widget.isEditMode) {
                                      _selectedWeightGoal.value = goal;
                                    } else {
                                      ref
                                          .read(authProvider.notifier)
                                          .setWeightGoal(goal);
                                    }
                                  },
                                ),
                              );
                            }),
                            12.verticalSpace,
                            _SectionTitle(label: 'Daily Steps Goal'),
                            14.verticalSpace,
                            Wrap(
                              spacing: 10.w,
                              runSpacing: 12.h,
                              children: GoalsSelectionScreen._dailyStepGoals
                                  .map((stepsGoal) {
                                return _DailyStepsGoalChip(
                                  stepsGoal: stepsGoal,
                                  selected: selectedSteps == stepsGoal,
                                  onTap: () {
                                    if (widget.isEditMode) {
                                      _selectedStepsGoal.value = stepsGoal;
                                    } else {
                                      ref
                                          .read(authProvider.notifier)
                                          .setDailyStepsGoal(stepsGoal);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: isSaving
                          ? (widget.isEditMode ? 'Saving...' : 'Saving...')
                          : (widget.isEditMode ? 'Update' : 'Finish Profile'),
                      isLoading: isSaving,
                      onTap: isSaving
                          ? null
                          : (widget.isEditMode ? _onUpdate : _onFinishProfile),
                    ),
                    28.verticalSpace,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.montserrat(
        size: 17.sp,
        color: AppColors.textPrimary,
        weight: FontWeight.w800,
      ),
    );
  }
}

class _WeightGoalOption extends StatelessWidget {
  const _WeightGoalOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: AppBorders.raised(
            color: selected ? AppColors.splashBlue : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.montserrat(
            size: 15.sp,
            color: AppColors.textPrimary,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DailyStepsGoalChip extends StatelessWidget {
  const _DailyStepsGoalChip({
    required this.stepsGoal,
    required this.selected,
    required this.onTap,
  });

  final int stepsGoal;
  final bool selected;
  final VoidCallback onTap;

  String get _label => stepsGoal.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 90.w,
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: AppBorders.raised(
            color: selected ? AppColors.splashBlue : AppColors.borderColor,
          ),
        ),
        child: Text(
          _label,
          style: AppTextStyles.montserrat(
            size: 15.sp,
            color: AppColors.textPrimary,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
