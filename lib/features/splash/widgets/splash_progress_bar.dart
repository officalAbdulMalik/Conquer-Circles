import 'package:flutter/material.dart';

class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF675FAA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(21413900), // Very large for pill shape
      ),
      child: Stack(
        children: [
          // Animated progress indicator
          Container(
            width: 208,
            height: 8,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF675FAA), // Purple
                  Color(0xFF53E4F3), // Cyan
                ],
              ),
              borderRadius: BorderRadius.circular(21413900),
            ),
          ),
        ],
      ),
    );
  }
}
