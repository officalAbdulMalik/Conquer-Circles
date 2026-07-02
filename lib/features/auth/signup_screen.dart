import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/core/utils/validators.dart';
import 'package:test_steps/features/auth/gender_selection_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/social_auth_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .signup(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    if (!mounted) return;

    if (result.success) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GenderSelectionScreen()));
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
        builder: (_) => hasCompletedOnboarding
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppCircularBackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    50.verticalSpace,
                    Text(
                      'Welcome To Conquer\nWorld',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.montserrat(
                        size: 24.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    30.verticalSpace,
                    AppTextInput(
                      controller: _nameController,
                      hintText: 'Name',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'Name'),
                      borderRadius: 20,
                      fillColor: AppColors.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    18.verticalSpace,
                    AppTextInput(
                      controller: _emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validateEmail,
                      borderRadius: 20,
                      fillColor: AppColors.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    18.verticalSpace,
                    AppTextInput(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: authState.signupPasswordObscured,
                      textInputAction: TextInputAction.done,
                      validator: AppValidators.validatePassword,
                      borderRadius: 20,
                      fillColor: AppColors.surface,
                      contentPadding: EdgeInsets.only(left: 16.w),
                      suffixIcon: IconButton(
                        onPressed: ref
                            .read(authProvider.notifier)
                            .toggleSignupPasswordVisibility,
                        icon: Icon(
                          authState.signupPasswordObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textPrimary,
                          size: 18.sp,
                        ),
                      ),
                    ),
                    28.verticalSpace,
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
                    30.verticalSpace,
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
                    24.verticalSpace,
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
                    86.verticalSpace,
                    PrimaryButton(
                      label: authState.isEmailAuthLoading
                          ? 'Signing up...'
                          : 'Sign up',
                      isLoading: authState.isEmailAuthLoading,
                      onTap: authState.isEmailAuthLoading ? null : _signup,
                    ),
                    16.verticalSpace,
                    _TermsCopy(),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _TermsCopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.montserrat(
      size: 14.sp,
      color: AppColors.textSecondary,
      weight: FontWeight.w400,
      height: 1.45,
    );
    final linkStyle = baseStyle.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: "By logging you're agree to our "),
          TextSpan(text: 'Terms of Service', style: linkStyle),
          const TextSpan(text: ' &\n'),
          TextSpan(text: 'Privacy Policy', style: linkStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
