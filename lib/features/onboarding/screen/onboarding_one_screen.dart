import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/gender_option_tile.dart';
import '../widgets/onboarding_footer_actions.dart';
import '../widgets/onboarding_progress_header.dart';

class OnboardingOneScreen extends StatelessWidget {
  const OnboardingOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.bgSoftPurple],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const OnboardingProgressHeader(),
                    const SizedBox(height: 84),
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandPurple,
                              Color(0xFF8B7FD4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPurple.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/onboarding_gender_badge.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'GENDER',
                        style: AppTextStyles.style(
                          fontFamily: 'Poppins',
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.brandPurple,
                          height: 1.5,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "What's Your Gender?",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.style(
                          fontFamily: 'Poppins',
                          size: 24,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          'This helps us personalize your fitness plan.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.style(
                            fontFamily: 'Poppins',
                            size: 14,
                            weight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const GenderOptionTile(emoji: '🏋️‍♂️', label: 'Male'),
                    const SizedBox(height: 12),
                    const GenderOptionTile(emoji: '🏋️‍♀️', label: 'Female'),
                    const SizedBox(height: 12),
                    const GenderOptionTile(emoji: '🧑‍🤝‍🧑', label: 'Other'),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: OnboardingFooterActions(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
