import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class EnergyUsageTile extends StatelessWidget {
  const EnergyUsageTile({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.amount,
    this.amountColor,
    required this.type,
  });

  final String title;
  final String description;
  final String date;
  final String amount;
  final Color? amountColor;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.w,
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E7FF), // indigo/blue background tint
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconForType(type),
                color: const Color(0xFF4F46E5), // Indigo blue color
                size: 20.sp,
              ),
            ),
          ),
          14.horizontalSpace,
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    weight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                4.verticalSpace,
                Text(
                  description,
                  style: AppTextStyles.montserrat(
                    size: 13.sp,
                    color: const Color(0xFF64748B),
                    weight: FontWeight.w400,
                  ),
                ),
                4.verticalSpace,
                Text(
                  date,
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: const Color(0xFF94A3B8),
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          // Amount
          Text(
            amount,
            style: AppTextStyles.montserrat(
              size: 16.sp,
              weight: FontWeight.w800,
              color: amountColor ?? const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'steps':
      case 'step_milestone':
        return Icons.directions_walk_rounded;
      case 'territory_battle':
      case 'territory_assault':
        return Icons.bolt_rounded;
      case 'purchase':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }
}
