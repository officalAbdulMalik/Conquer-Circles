import 'package:flutter/material.dart';

import 'package:test_steps/features/auth/login_screen.dart';
import 'package:test_steps/features/onboarding/screen/onboarding_two_screen.dart';
import 'package:test_steps/features/onboarding/widgets/onboarding_step_template.dart';

class OnboardingOneScreen extends StatelessWidget {
  const OnboardingOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepTemplate(
      stepIndex: 0,
      title: 'Walk to Conquer',
      subtitle: 'Every step you take claims real-world territory.',
      primaryCtaLabel: 'Start Walking',
      secondaryCtaLabel: 'Skip',
      illustrationType: OnboardingIllustrationType.walkToConquer,
      onPrimaryPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OnboardingTwoScreen()));
      },
      onSecondaryPressed: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
