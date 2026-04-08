import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
                  trackColor: AppColors.bgSoftPurple,
                  showShimmer: i == 0,
                ),
              ),
              if (i < 4) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '1 / 5',
          style: AppTextStyles.style(
            fontFamily: 'Inter',
            size: 12,
            weight: FontWeight.w400,
            color: const Color(0xFFAAAAAA),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
