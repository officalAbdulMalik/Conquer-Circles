import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class MapSearchOverlay extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const MapSearchOverlay({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextInput(
      controller: controller,
      onSubmitted: onSearch,
      hintText: 'Find territory...',
      height: 48,
      borderRadius: 16,
      border: Border.all(
        color: const Color(0xFF0D968B).withValues(alpha: 0.05),
        width: 1.w,
      ),
      prefixIcon: Icon(
        Icons.search,
        color: const Color(0xFF0D968B),
        size: 20.sp,
      ),
      textStyle: AppTextStyles.montserrat(
        size: 14.sp,
        color: const Color(0xFF0F172A),
        weight: FontWeight.w600,
      ),
      hintStyle: AppTextStyles.montserrat(
        size: 14.sp,
        color: const Color(0xFF64748B),
        weight: FontWeight.w500,
      ),
    );
  }
}
