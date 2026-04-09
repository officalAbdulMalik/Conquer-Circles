import 'package:flutter/material.dart';

import 'package:test_steps/features/onboarding/screen/onboarding_five_screen.dart';
import 'package:test_steps/features/onboarding/widgets/onboarding_step_template.dart';

class OnboardingFourScreen extends StatelessWidget {
  const OnboardingFourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepTemplate(
      stepIndex: 3,
      title: 'Build & Defend',
      subtitle: 'Strengthen your territory and protect your land.',
      primaryCtaLabel: 'Build My Territory',
      secondaryCtaLabel: 'Back',
      illustrationType: OnboardingIllustrationType.buildAndDefend,
      onPrimaryPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OnboardingFiveScreen()));
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}
