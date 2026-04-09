import 'package:flutter/material.dart';

import 'package:test_steps/features/onboarding/screen/onboarding_four_screen.dart';
import 'package:test_steps/features/onboarding/widgets/onboarding_step_template.dart';

class OnboardingThreeScreen extends StatelessWidget {
  const OnboardingThreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepTemplate(
      stepIndex: 2,
      title: 'Compete with Friends',
      subtitle: 'Join circles and battle for control.',
      primaryCtaLabel: 'Join a Circle',
      secondaryCtaLabel: 'Back',
      illustrationType: OnboardingIllustrationType.competeWithFriends,
      onPrimaryPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OnboardingFourScreen()));
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}
