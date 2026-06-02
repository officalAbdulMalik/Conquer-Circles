import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class CircleSearchField extends StatelessWidget {
  const CircleSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTextInput(
      hintText: 'Search circles...',
      border: AppBorders.raised(color: const Color(0xFFE5E7EB)),
      prefixIcon: Icon(Icons.search_rounded, size: 19.sp),
    );
  }
}
