import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7D72CC), Color(0xFF7266CB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7D72CC,
                            ).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4BD4E4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4BD4E4,
                              ).withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -8,
                      bottom: 6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF74D1E7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2E35),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to begin your fitness quest',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF9A9CA7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Email',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF3F3F46),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _fieldBox(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF3F3F46),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFB1B3C1),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFB5B7CC),
                      size: 20,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Password',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF3F3F46),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _fieldBox(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF3F3F46),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFB1B3C1),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFB5B7CC),
                      size: 20,
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
                        color: const Color(0xFFB5B7CC),
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Password',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF3F3F46),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _fieldBox(
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF3F3F46),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFB1B3C1),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFFB5B7CC),
                      size: 20,
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
                        color: const Color(0xFFB5B7CC),
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.brandPurple.withValues(alpha: 0.35),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign Up',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontSize: 28 / 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
             20.verticalSpace,
            
               Row(
                children: [
                  Expanded(
                    child: _socialButton(
                      label: 'Apple',
                      icon: Icons.apple_rounded,
                      foreground: Colors.white,
                      background: const Color(0xFF181A1D),
                      borderColor: const Color(0xFF181A1D),
                      onPressed: () async {
                        await _supabaseService.signInWithApple();
                        await NotificationService.sendWelcomeNotification();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _socialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      foreground: const Color(0xFF4B4D58),
                      background: const Color(0xFFF0F1F8),
                      borderColor: const Color(0xFFE6E8F1),
                      onPressed: () async {
                        await _supabaseService.signInWithGoogle();
                        await NotificationService.sendWelcomeNotification();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
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
    );
  }
  

    Widget _socialButton({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldBox({required Widget child}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFA),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: child,
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
