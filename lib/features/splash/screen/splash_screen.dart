import 'package:flutter/material.dart';
import 'package:test_steps/features/onboarding/screen/onboarding_one_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/splash_logo.dart';
import '../widgets/splash_decorative_elements.dart';
import '../widgets/splash_floating_vector_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(begin: 0, end: 1).animate(_progressController);

    _progressController.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // TODO: Navigate to next screen
       Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingOneScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Background container with gradient
            Container(
              width: screenSize.width,
              height: screenSize.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.splashGradientStart, // Light purple
                    AppColors.splashGradientMid, // White
                    AppColors.splashGradientEnd, // Light cyan
                  ],
                  stops: [0.08, 0.41, 0.91],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative floating circles
                  const SplashDecorativeElements(),

                  // Main content centered
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo with badges
                        const SplashLogo(),

                        const SizedBox(height: 38),

                        // FitQuest heading
                        Text(
                          'FitQuest',
                          style: AppTextStyles.splashHeading,
                        ),

                        const SizedBox(height: 11),

                        // Subtitle
                        Text(
                          'Level up your fitness journey',
                          style: AppTextStyles.splashParagraph,
                        ),

                        const SizedBox(height: 78),

                        // Progress bar
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background
                                Container(
                                  width: 208,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF675FAA)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        21413900), // Very large for pill shape
                                  ),
                                ),
                                // Progress fill
                                Container(
                                  width: 208 * _progressAnimation.value,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF675FAA),
                                        Color(0xFF53E4F3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        21413900),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Floating vector icons
                  const SplashFloatingVectorIcons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
