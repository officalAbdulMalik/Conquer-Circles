import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 113,
      width: 113,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main purple rounded square with fire icon
          Container(
            width: 113,
            height: 113,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF675FAA), // Purple
                  Color(0xFF8B7FD4), // Light Purple
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.splashPrimaryPurple.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/splash_icon_1.svg',
                width: 56,
                height: 56,
              ),
            ),
          ),

          // Top-right cyan badge with bolt icon
          Positioned(
            top: -13.69,
            right: -14.4,
            child: Container(
              width: 47.4,
              height: 47.4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF53E4F3), // Cyan
                    Color(0xFF3DD4E3), // Dark Cyan
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.splashCyan.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/splash_icon_2.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),

          // Bottom-left light cyan badge with heart icon
          Positioned(
            bottom: -14.4,
            left: -14.4,
            child: Container(
              width: 44.8,
              height: 44.8,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF99D7E9), // Light Cyan
                    Color(0xFF7BC5DA), // Darker Light Cyan
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.splashLightCyan.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/splash_icon_3.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
