import 'package:flutter/material.dart';

import 'package:test_steps/features/auth/login_screen.dart';
import 'package:test_steps/features/onboarding/widgets/onboarding_step_template.dart';

class OnboardingFiveScreen extends StatelessWidget {
  const OnboardingFiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepTemplate(
      stepIndex: 4,
      title: 'Earn & Level Up',
      subtitle: 'Unlock badges, rewards, and become the top player.',
      primaryCtaLabel: 'Get Started',
      secondaryCtaLabel: 'Back',
      illustrationType: OnboardingIllustrationType.earnAndLevelUp,
      onPrimaryPressed: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}
