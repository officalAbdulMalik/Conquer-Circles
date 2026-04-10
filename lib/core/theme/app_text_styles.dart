import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle style({
    required String fontFamily,
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle poppins({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
  }) {
    return style(
      fontFamily: 'Poppins',
      size: size,
      color: color,
      weight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle inter({
    required double size,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
  }) {
    return style(
      fontFamily: 'Inter',
      size: size,
      color: color ?? AppColors.textSecondaryLight,
      weight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Core styles
  static TextStyle get heading1 => poppins(
    size: 28,
    weight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
    height: 1.25,
  );

  static TextStyle get heading2 => poppins(
    size: 24,
    weight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.33,
  );

  static TextStyle get heading3 => poppins(
    size: 20,
    weight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.4,
  );

  static TextStyle get bodyLarge => poppins(
    size: 18,
    weight: FontWeight.w500,
    color: AppColors.textPrimaryLight,
    height: 1.5,
  );

  static TextStyle get bodyMedium => poppins(
    size: 16,
    weight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
    height: 1.5,
  );

  static TextStyle get bodySmall => inter(
    size: 14,
    color: AppColors.textLight,
    weight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get caption => poppins(
    size: 12,
    weight: FontWeight.w400,
    color: AppColors.textSecondaryLight,
    height: 1.33,
  );

  static TextStyle get screenTitle => poppins(
    size: 22,
    weight: FontWeight.w700,
    color: AppColors.textNavy,
    height: 1.2,
  );

  static TextStyle get sectionTitle => poppins(
    size: 18,
    weight: FontWeight.w700,
    color: AppColors.textNavy,
    height: 1.2,
  );

  static TextStyle get cardTitle => poppins(
    size: 16,
    weight: FontWeight.w700,
    color: AppColors.textNavy,
    height: 1.2,
  );

  static TextStyle get cardSubtitle =>
      inter(size: 12, color: AppColors.textSecondary, weight: FontWeight.w500);

  static TextStyle get chipLabel =>
      inter(size: 11, color: AppColors.textSecondary, weight: FontWeight.w600);

  static TextStyle get buttonLabel => poppins(
    size: 14,
    color: AppColors.surface,
    weight: FontWeight.w600,
    height: 1.2,
  );

  // Splash styles
  static TextStyle get splashHeading => poppins(
    size: 36,
    weight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get splashParagraph => poppins(
    size: 15,
    weight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
}
