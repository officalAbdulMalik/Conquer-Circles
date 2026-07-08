import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/core/utils/validators.dart';
import 'package:test_steps/features/auth/forgot_password_screen.dart';
import 'package:test_steps/features/auth/gender_selection_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/social_auth_button.dart';

import 'signup_screen.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    if (!mounted) return;

    if (result.success) {
      final hasCompletedOnboarding = await ref
          .read(authProvider.notifier)
          .isCurrentProfileOnboardingComplete();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => hasCompletedOnboarding
              ? const MainNavigation()
              : const GenderSelectionScreen(),
        ),
        (route) => false,
      );
    } else {
      _showAuthError(result.error);
    }
  }

  Future<void> _continueWithGoogle() async {
    await _completeSocialAuth(
      ref.read(authProvider.notifier).continueWithGoogle,
    );
  }

  Future<void> _continueWithApple() async {
    await _completeSocialAuth(
      ref.read(authProvider.notifier).continueWithApple,
    );
  }

  Future<void> _completeSocialAuth(
    Future<AuthActionResult> Function() signIn,
  ) async {
    final result = await signIn();
    if (!mounted) return;

    if (!result.success) {
      _showAuthError(result.error);
      return;
    }
    if (!result.completedSession) return;

    final hasCompletedOnboarding = await ref
        .read(authProvider.notifier)
        .isCurrentProfileOnboardingComplete();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => hasCompletedOnboarding
            ? const MainNavigation()
            : const GenderSelectionScreen(),
      ),
      (route) => false,
    );
  }

  void _showAuthError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Something went wrong.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(height: 260.h, color: AppColors.surface.withValues(alpha: 0.7),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppCircularBackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    40.verticalSpace,
                    Text(
                      'Login To Conquer The\nWorld',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.montserrat(
                        size: 24.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    30.verticalSpace,
                    AppTextInput(
                      controller: _emailController,
                      hintText: 'aqib@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validateEmail,

                      borderRadius: 20,
                      fillColor: AppColors.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    26.verticalSpace,
                    AppTextInput(
                      controller: _passwordController,
                      hintText: '********',
                      obscureText: authState.loginPasswordObscured,
                      textInputAction: TextInputAction.done,
                      validator: AppValidators.validatePassword,

                      borderRadius: 20,
                      fillColor: AppColors.surface,
                      contentPadding: EdgeInsets.only(left: 16.w),
                      suffixIcon: IconButton(
                        onPressed: ref
                            .read(authProvider.notifier)
                            .toggleLoginPasswordVisibility,
                        icon: Icon(
                          authState.loginPasswordObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textPrimary,
                          size: 18.sp,
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _openForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 30.h),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.montserrat(
                            size: 14.sp,
                            color: AppColors.textSecondary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    25.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.dividerColor,
                            thickness: 1.w,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            'Or continue with',
                            style: AppTextStyles.montserrat(
                              size: 14.sp,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.dividerColor,
                            thickness: 1.w,
                          ),
                        ),
                      ],
                    ),
                    25.verticalSpace,
                    SocialAuthButton(
                      label: 'Continue with Google',
                      icon: SvgPicture.asset(
                        'assets/icons/google_icon.svg',
                        width: 20.w,
                        height: 20.w,
                      ),
                      onTap: authState.isSocialAuthLoading
                          ? null
                          : _continueWithGoogle,
                    ),
                    26.verticalSpace,
                    SocialAuthButton(
                      label: 'Continue with Apple',
                      icon: SvgPicture.asset(
                        'assets/icons/apple_icon.svg',
                        width: 20.w,
                        height: 20.w,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: authState.isSocialAuthLoading
                          ? null
                          : _continueWithApple,
                    ),
                    136.verticalSpace,
                    PrimaryButton(
                      label: authState.isEmailAuthLoading
                          ? 'Logging in...'
                          : 'Login',
                      isLoading: authState.isEmailAuthLoading,
                      onTap: authState.isEmailAuthLoading ? null : _login,
                    ),
                    18.verticalSpace,
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account ? ",
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSignup,
                          child: Text(
                            'Sign up',
                            style: AppTextStyles.montserrat(
                              size: 16,
                              color: AppColors.splashBlue,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
