import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/widgets/circle_icon_picker.dart';
import 'package:test_steps/features/social/widgets/circle_created_dialog.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/custom_app_dialog.dart';
import 'package:test_steps/widgets/shared/dashboard_segmented_tab_bar.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class CreateCircleOnboardingView extends ConsumerStatefulWidget {
  const CreateCircleOnboardingView({super.key});

  @override
  ConsumerState<CreateCircleOnboardingView> createState() =>
      _CreateCircleOnboardingViewState();
}

class _CreateCircleOnboardingViewState
    extends ConsumerState<CreateCircleOnboardingView> {
  final TextEditingController _circleNameController = TextEditingController();

  bool _showIconPicker = false;
  bool _isPrivate = false;
  late String _selectedIconId;

  @override
  initState() {
    super.initState();
    _selectedIconId = ref.read(circlesProvider.notifier).circleImages.first;
  }

  @override
  void dispose() {
    _circleNameController.dispose();
    super.dispose();
  }

  Future<void> _createCircle() async {
    final circleName = _circleNameController.text.trim();
    if (circleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a circle name.')),
      );
      return;
    }

    final response = await ref
        .read(circlesProvider.notifier)
        .createCircle(
          name: circleName,
          isPrivate: _isPrivate,
          iconUrl: _selectedIconId,
        );
    final success = response['success'] == true;

    if (!mounted) return;

    if (success) {
      await showCustomAppDialog<void>(
        context: context,
        dialog: CircleCreatedDialog(
          onClose: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      );
      return;
    }

    final message = response['error']?.toString() ?? 'Failed to create circle';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 26.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: AppBorders.raised(),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Create Circle',
                            style: AppTextStyles.montserrat(
                              size: 18.sp,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 38.w),
                    ],
                  ),
                  32.verticalSpace,
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        setState(() => _showIconPicker = !_showIconPicker),
                    child: Container(
                      width: 90.w,
                      height: 90.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDEBFF),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 34.sp,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Image.network(
                              _selectedIconId,
                              width: 34.sp,
                              height: 34.sp,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 24.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  12.verticalSpace,
                  InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () =>
                        setState(() => _showIconPicker = !_showIconPicker),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        'Choose Icon',
                        style: AppTextStyles.montserrat(
                          size: 12.sp,
                          color: AppColors.blueColor,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (_showIconPicker) ...[
                    14.verticalSpace,
                    CircleIconPicker(
                      options: ref.read(circlesProvider.notifier).circleImages,
                      selectedId: _selectedIconId,
                      onSelected: (option) =>
                          setState(() => _selectedIconId = option),
                    ),
                  ],
                  20.verticalSpace,
                  AppTextInput(
                    controller: _circleNameController,
                    hintText: 'Circle name',
                    height: 48,
                    borderRadius: 18,
                    textCapitalization: TextCapitalization.words,
                    border: AppBorders.raised(),
                    hintStyle: AppTextStyles.montserrat(
                      size: 15.sp,
                      color: const Color(0xFFC6CCD7),
                      weight: FontWeight.w500,
                    ),
                  ),
                  10.verticalSpace,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Unique name, no emojis in name',
                      style: AppTextStyles.montserrat(
                        size: 13.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                  20.verticalSpace,
                  DashboardSegmentedTabBar(
                    labels: const ['Public', 'Private'],
                    selectedIndex: _isPrivate ? 1 : 0,
                    onChanged: (index) {
                      setState(() => _isPrivate = index == 1);
                    },
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: circlesState.isCreating
                        ? 'Creating...'
                        : 'Create Circle',
                    onTap: circlesState.isCreating ? null : _createCircle,
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
