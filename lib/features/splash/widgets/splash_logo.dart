import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      width: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bgDeep.withValues(alpha: 0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
          ),
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, Color(0xFFEAF6FF)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bgDeep.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.splashAqua.withValues(alpha: 0.22),
                        AppColors.splashBlue.withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/dashboard_shield_icon.svg',
                  width: 46,
                  height: 46,
                  colorFilter: const ColorFilter.mode(
                    AppColors.splashBlueDeep,
                    BlendMode.srcIn,
                  ),
                ),
                Positioned(
                  right: 23,
                  top: 23,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.splashGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 2,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.splashAqua, Color(0xFF2CC6DC)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.splashAqua.withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/splash_icon_2.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.splashGold, Color(0xFFFFB84D)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.splashGold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/splash_icon_3.svg',
                  width: 17,
                  height: 17,
                  colorFilter: const ColorFilter.mode(
                    AppColors.surface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
