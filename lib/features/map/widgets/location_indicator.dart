import 'package:flutter/material.dart';

class PulsingLocationIndicator extends StatefulWidget {
  const PulsingLocationIndicator({super.key});

  @override
  State<PulsingLocationIndicator> createState() => _PulsingLocationIndicatorState();
}

class _PulsingLocationIndicatorState extends State<PulsingLocationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Container(
              width: 80 * _controller.value,
              height: 80 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE).withOpacity(1 - _controller.value),
              ),
            ),
            // Middle pulse
            Container(
              width: 40 * _controller.value,
              height: 40 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE).withOpacity(0.5 * (1 - _controller.value)),
              ),
            ),
            // Core
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF22D3EE),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class YouAreHereLabel extends StatelessWidget {
  const YouAreHereLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'YOU ARE HERE',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
