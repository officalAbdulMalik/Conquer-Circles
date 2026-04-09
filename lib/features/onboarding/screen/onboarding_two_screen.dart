import 'package:flutter/material.dart';

import 'package:test_steps/features/onboarding/screen/onboarding_three_screen.dart';
import 'package:test_steps/features/onboarding/widgets/onboarding_step_template.dart';

class OnboardingTwoScreen extends StatelessWidget {
  const OnboardingTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepTemplate(
      stepIndex: 1,
      title: 'Own the Map',
      subtitle: 'Turn the streets around you into your territory.',
      primaryCtaLabel: 'Claim Territory',
      secondaryCtaLabel: 'Back',
      illustrationType: OnboardingIllustrationType.ownTheMap,
      onPrimaryPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OnboardingThreeScreen()),
        );
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}
