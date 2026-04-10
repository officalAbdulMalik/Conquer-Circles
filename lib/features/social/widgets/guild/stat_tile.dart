import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/guild_models.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.stat});
  final GuildStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.bgProgress,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          stat.icon,
          6.verticalSpace,
          Text(
            stat.value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          2.verticalSpace,
          Text(
            stat.label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
