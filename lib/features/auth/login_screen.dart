import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/core/utils/validators.dart';
import 'package:test_steps/widgets/shared/app_button.dart';
import 'package:test_steps/widgets/shared/app_text_fileds.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _supabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainNavigation()),
          (route) => false,
        );
        await NotificationService.sendWelcomeNotification();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
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
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1,
              ),
              8.verticalSpace,
              Text(
                'Sign in to continue your quest',
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
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.iconColor,
                ),
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
              10.verticalSpace,
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: AppColors.brandPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: AppTextStyles.bodySmall.copyWith(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
              AppButton(
                label: 'Sign In',
                onPressed: _isLoading ? null : _login,
                // icon: Icons.arrow_forward_rounded,
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFA4A6B0),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
    super.dispose();
  }
}
