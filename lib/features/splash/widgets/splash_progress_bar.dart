import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(21413900), // Very large for pill shape
      ),
      child: Stack(
        children: [
          // Animated progress indicator
          Container(
            width: 208,
            height: 8,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.brandPurple, // Purple
                  AppColors.brandCyan, // Cyan
                ],
              ),
              borderRadius: BorderRadius.circular(21413900),
            ),
          ),
        ],
      ),
    );
  }
}
