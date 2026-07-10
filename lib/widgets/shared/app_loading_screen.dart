import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/splash/widgets/splash_logo.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

/// A branded stand-in for bare loading spinners: pulses the app logo while
/// auth/session state resolves. Swap in wherever a `CircularProgressIndicator`
/// would otherwise flash up alone.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.55,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBlue,
      body: Stack(
        children: [
          AppBackgroundImage(height: 281, color: const Color(0xff4C6FFF)),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(scale: _scale.value, child: child),
              ),
              child: const SplashLogo(),
            ),
          ),
        ],
      ),
    );
  }
}
