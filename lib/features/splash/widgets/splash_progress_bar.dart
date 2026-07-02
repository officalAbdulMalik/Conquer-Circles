import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      height: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.22),
              ),
              child: const SizedBox.expand(),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.splashAqua.withValues(alpha: 0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.splashAqua.withValues(alpha: 0.55),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
