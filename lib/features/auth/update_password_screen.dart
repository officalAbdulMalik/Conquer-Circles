import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/core/utils/validators.dart';
import 'package:test_steps/features/auth/gender_selection_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Visibility toggles: ValueNotifiers so only each input rebuilds.
  final ValueNotifier<bool> _passwordObscured = ValueNotifier(true);
  final ValueNotifier<bool> _confirmPasswordObscured = ValueNotifier(true);

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .updatePassword(password: _passwordController.text.trim());
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to update password.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully.')),
    );

    final hasCompletedOnboarding = await ref
        .read(authProvider.notifier)
        .isCurrentProfileOnboardingComplete();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => hasCompletedOnboarding
            ? const MainNavigation()
            : const GenderSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    118.verticalSpace,
                    Text(
                      'Update Password',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.montserrat(
                        size: 24.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    12.verticalSpace,
                    Text(
                      'Choose a new password for your account.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.montserrat(
                        size: 14.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                    34.verticalSpace,
                    ValueListenableBuilder<bool>(
                      valueListenable: _passwordObscured,
                      builder: (context, obscured, _) => AppTextInput(
                        controller: _passwordController,
                        hintText: 'New password',
                        obscureText: obscured,
                        textInputAction: TextInputAction.next,
                        validator: AppValidators.validatePassword,
                        borderRadius: 20,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.only(left: 16.w),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              _passwordObscured.value = !obscured,
                          icon: Icon(
                            obscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textPrimary,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    18.verticalSpace,
                    ValueListenableBuilder<bool>(
                      valueListenable: _confirmPasswordObscured,
                      builder: (context, obscured, _) => AppTextInput(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm password',
                        obscureText: obscured,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            AppValidators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                        borderRadius: 20,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.only(left: 16.w),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              _confirmPasswordObscured.value = !obscured,
                          icon: Icon(
                            obscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textPrimary,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    34.verticalSpace,
                    PrimaryButton(
                      label: authState.isPasswordUpdating
                          ? 'Updating...'
                          : 'Update Password',
                      isLoading: authState.isPasswordUpdating,
                      onTap: authState.isPasswordUpdating
                          ? null
                          : _updatePassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordObscured.dispose();
    _confirmPasswordObscured.dispose();
    super.dispose();
  }
}
