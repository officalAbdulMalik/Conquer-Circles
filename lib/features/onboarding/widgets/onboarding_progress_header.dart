import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/animated_gradient_progress_bar.dart';

class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            for (int i = 0; i < 5; i++) ...[
              Expanded(
                child: AnimatedGradientProgressBar(
                  value: i == 0 ? 1 : 0,
                  height: 6,
                  trackColor: AppColors.onboardingStepTrack,
                  showShimmer: i == 0,
                ),
              ),
              if (i < 4) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '1 / 5',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFFAAAAAA),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
