import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/features/auth/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingFooterActions extends StatelessWidget {
  const OnboardingFooterActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 96,
          height: 48,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/onboarding_back_arrow.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 128.5,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.bgSoftPurple.withValues(
                alpha: 0.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 16,
                    weight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/onboarding_next_arrow.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
