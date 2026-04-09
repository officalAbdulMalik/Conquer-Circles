import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class SeasonRecapScopeSwitcher extends StatefulWidget {
  const SeasonRecapScopeSwitcher({
    super.key,
    this.initialAllTime = true,
    required this.onChanged,
  });

  final bool initialAllTime;
  final ValueChanged<bool> onChanged;

  @override
  State<SeasonRecapScopeSwitcher> createState() =>
      _SeasonRecapScopeSwitcherState();
}

class _SeasonRecapScopeSwitcherState extends State<SeasonRecapScopeSwitcher> {
  late bool isAllTime;

  @override
  void initState() {
    super.initState();
    isAllTime = widget.initialAllTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (!isAllTime) {
                setState(() => isAllTime = true);
                widget.onChanged(true);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isAllTime ? AppColors.brandPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                'All Time',
                style: AppTextStyles.inter(
                  size: 11,
                  color: isAllTime ? AppColors.surface : AppColors.textSecondary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (isAllTime) {
                setState(() => isAllTime = false);
                widget.onChanged(false);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: !isAllTime ? AppColors.brandPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                'Season',
                style: AppTextStyles.inter(
                  size: 11,
                  color: !isAllTime ? AppColors.surface : AppColors.textSecondary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
