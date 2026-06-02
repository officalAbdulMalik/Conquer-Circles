import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.isLoading = false,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          width: width ?? double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueColor,
            borderRadius: BorderRadius.circular(26),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: textStyle ??
                      AppTextStyles.montserrat(
                        size: 16.sp,
                        color: Colors.white,
                        weight: FontWeight.w600,
                      ),
                ),
        ),
      ),
    );
  }
}
