import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class AppCircularBackButton extends StatelessWidget {
  const AppCircularBackButton({super.key, this.onTap, this.size = 34});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.borderColor)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: size.w,
          height: size.w,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}
