import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashFloatingVectorIcons extends StatelessWidget {
  const SplashFloatingVectorIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left floating icon (rotated)
        Positioned(
          left: 64.62,
          top: 163.49,
          child: Transform.rotate(
            angle: 8.94 * 3.14159 / 180, // Convert degrees to radians
            child: SizedBox(
              width: 22.864,
              height: 22.864,
              child: SvgPicture.asset(
                'assets/icons/splash_vector_1.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Right-side complex icon (rotated)
        Positioned(
          right: 64.73,
          top: 230.82,
          child: Transform.rotate(
            angle: -9.54 * 3.14159 / 180,
            child: SizedBox(
              width: 27.645,
              height: 27.645,
              child: const _SplashTrophyIcon(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashTrophyIcon extends StatelessWidget {
  const _SplashTrophyIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 7,
          top: 2,
          width: 14,
          height: 15,
          child: SvgPicture.asset('assets/icons/splash_vector_7.svg'),
        ),
        Positioned(
          left: 2,
          top: 4,
          width: 6,
          height: 7,
          child: SvgPicture.asset('assets/icons/splash_vector_2.svg'),
        ),
        Positioned(
          right: 2,
          top: 4,
          width: 6,
          height: 7,
          child: SvgPicture.asset('assets/icons/splash_vector_3.svg'),
        ),
        Positioned(
          left: 5,
          bottom: 2,
          width: 18,
          height: 2,
          child: SvgPicture.asset('assets/icons/splash_vector_4.svg'),
        ),
        Positioned(
          left: 7,
          top: 15,
          width: 5,
          height: 9,
          child: SvgPicture.asset('assets/icons/splash_vector_5.svg'),
        ),
        Positioned(
          right: 7,
          top: 15,
          width: 5,
          height: 9,
          child: SvgPicture.asset('assets/icons/splash_vector_6.svg'),
        ),
      ],
    );
  }
}
