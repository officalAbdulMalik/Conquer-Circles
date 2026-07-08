import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.onBackTap,
  });

  final String title;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 18.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 0,
          child: AppCircularBackButton(onTap: onBackTap),
        ),
      ],
    );
  }
}
