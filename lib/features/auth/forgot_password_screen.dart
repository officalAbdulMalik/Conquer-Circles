import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/core/utils/validators.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Pure view state (which copy/button variant to show) — ValueNotifier so
  /// no setState and only the form subtree rebuilds. The reset call itself
  /// lives in authProvider.
  final ValueNotifier<bool> _linkSent = ValueNotifier(false);

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text.trim());
    if (!mounted) return;

    if (result.success) {
      _linkSent.value = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? 'Failed to send reset link.'),
        backgroundColor: AppColors.error,
      ),
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
                child: ValueListenableBuilder<bool>(
                  valueListenable: _linkSent,
                  builder: (context, linkSent, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppCircularBackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    86.verticalSpace,
                    Text(
                      linkSent ? 'Check Your Email' : 'Forgot Password?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.montserrat(
                        size: 24.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    12.verticalSpace,
                    Text(
                      linkSent
                          ? 'Open the reset link we sent to continue.'
                          : 'Enter your account email to receive a reset link.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.montserrat(
                        size: 14.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                    32.verticalSpace,
                    AppTextInput(
                      controller: _emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: AppValidators.validateEmail,
                      enabled: !linkSent,
                      borderRadius: 20,
                      fillColor: AppColors.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    34.verticalSpace,
                    PrimaryButton(
                      label: linkSent
                          ? 'Back to Login'
                          : authState.isPasswordResetLoading
                          ? 'Sending...'
                          : 'Send Reset Link',
                      isLoading: authState.isPasswordResetLoading,
                      onTap: authState.isPasswordResetLoading
                          ? null
                          : linkSent
                          ? () => Navigator.of(context).maybePop()
                          : _sendResetLink,
                    ),
                    if (linkSent) ...[
                      16.verticalSpace,
                      TextButton(
                        onPressed: authState.isPasswordResetLoading
                            ? null
                            : () {
                                _linkSent.value = false;
                                _sendResetLink();
                              },
                        child: Text(
                          'Send again',
                          style: AppTextStyles.montserrat(
                            size: 14.sp,
                            color: AppColors.blueColor,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                  ),
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
    _emailController.dispose();
    _linkSent.dispose();
    super.dispose();
  }
}
