import 'package:flutter/material.dart';

class SplashDecorativeElements extends StatelessWidget {
  const SplashDecorativeElements({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating elements with various sizes and opacities
        // Top-left small element
        Positioned(
          left: 44.03,
          top: 128.77,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF675FAA).withValues(alpha: 0.53),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          left: 92.47,
          top: 321.52,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFF53E4F3).withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          left: 140.91,
          top: 514.75,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF675FAA).withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          left: 189.34,
          top: 708.13,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFF53E4F3).withValues(alpha: 0.49),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          left: 237.78,
          top: 136.69,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF675FAA).withValues(alpha: 0.44),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          right: 93.77,
          top: 330.01,
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              color: const Color(0xFF53E4F3).withValues(alpha: 0.39),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          right: 45.34,
          top: 523.24,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF675FAA).withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Element
        Positioned(
          right: -3.1,
          top: 716.4,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: const Color(0xFF53E4F3).withValues(alpha: 0.31),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
