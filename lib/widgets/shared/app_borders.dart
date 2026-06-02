import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class AppBorders {
  const AppBorders._();

  static Border raised({Color color = AppColors.borderColor}) {
    return Border(
      top: BorderSide(color: color, width: 1.w),
      right: BorderSide(color: color, width: 1.w),
      bottom: BorderSide(color: color, width: 3.w),
      left: BorderSide(color: color, width: 1.w),
    );
  }
}
