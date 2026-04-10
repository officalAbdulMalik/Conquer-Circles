import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/core/utils/validators.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/widgets/shared/app_button.dart';
import 'package:test_steps/widgets/shared/app_text_fileds.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _supabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Please check your email for verification.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await NotificationService.sendWelcomeNotification();
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = 'Signup failed: ${e.message}';
        if (e.code == 'over_email_send_rate_limit') {
          message =
              'Too many signup attempts. Please wait a few minutes and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint('here is error ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top * 2),
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1,
              ),
              8.verticalSpace,
              Text(
                'Sign up to begin your fitness quest',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              30.verticalSpace,
              AppTextField(
                controller: _emailController,
                hintText: 'your@email.com',
                label: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: AppColors.iconColor,
                ),
                validator: AppValidators.validateEmail,
              ),
              16.verticalSpace,
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: _obscurePassword,
                hintText: 'Enter password',
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppColors.iconColor,
                ),
                validator: AppValidators.validatePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.iconColor,
                    size: 20,
                  ),
                ),
              ),
              16.verticalSpace,
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscureText: _obscureConfirmPassword,
                hintText: 'Confirm password',
                prefixIcon: Icon(
                  Icons.lock_reset_rounded,
                  size: 20,
                  color: AppColors.iconColor,
                ),
                validator: (value) => AppValidators.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.iconColor,
                    size: 20,
                  ),
                ),
              ),
              20.verticalSpace,
              AppButton(
                label: 'Sign Up',
                onPressed: _isLoading ? null : _signup,
              ),
              30.verticalSpace,
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.dividerColor)),
                ],
              ),
              30.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      backgroundColor: AppColors.bgDark,
                      icon: SvgPicture.asset('assets/icons/apple_icon.svg'),
                      label: 'Apple',
                      onPressed: () async {
                        await _supabaseService.signInWithApple();
                        await NotificationService.sendWelcomeNotification();
                      },
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: AppButton(
                      backgroundColor: AppColors.fillColor,
                      icon: SvgPicture.asset('assets/icons/google_icon.svg'),
                      textStyle: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black,
                      ),
                      label: 'Google',
                      onPressed: () async {
                        await _supabaseService.signInWithGoogle();
                        await NotificationService.sendWelcomeNotification();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFA4A6B0),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Login',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w700,
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
