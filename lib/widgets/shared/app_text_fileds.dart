import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText,
    this.label,
    this.validator,
  });
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool? obscureText;
  final String? label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          obscureText: obscureText ?? false,
          validator: validator,
          decoration: InputDecoration(
            fillColor: AppColors.fillColor,
            filled: true,
            hintText: hintText ?? 'your@email.com',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            prefixIcon:
                prefixIcon ??
                Icon(
                  Icons.email_outlined,
                  color: const Color(0xFFB5B7CC),
                  size: 20,
                ),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: Colors.redAccent,
              fontSize: 12.sp,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: AppColors.fillColor, width: 1.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: AppColors.brandPurple.withAlpha(0x80),
                width: 1.w,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.redAccent, width: 1.w),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.redAccent, width: 1.w),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: AppColors.surface.withValues(alpha: 0.5),
                width: 1.w,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
