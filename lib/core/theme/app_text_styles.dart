import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._(); // prevent instantiation

  // Splash Screen Styles
  static const TextStyle splashHeading = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 36,
    fontWeight: FontWeight.w800, // ExtraBold
    color: AppColors.splashTextPrimary,
    height: 1.3, // 46.8px / 36px
    letterSpacing: 0,
  );

  static const TextStyle splashParagraph = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.splashTextSecondary,
    height: 1.5, // 22.5px / 15px
    letterSpacing: 0,
  );

  // Existing heading styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
    height: 1.25,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.33,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryLight,
    height: 1.33,
  );

  // Onboarding Screen Styles
  static const TextStyle onboardingStepLabel = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.onboardingLabel,
    height: 1.5,
    letterSpacing: 2,
  );

  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onboardingTitle,
    height: 1.3,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSubtitle,
    height: 1.5,
  );

  static const TextStyle onboardingOption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onboardingTitle,
    height: 1.5,
  );

  static const TextStyle onboardingBack = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onboardingBackText,
    height: 1.5,
  );

  static const TextStyle onboardingNext = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.5,
  );
}
