import 'package:flutter/material.dart';

class AnimatedGradientProgressBar extends StatefulWidget {
  const AnimatedGradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.trackColor = const Color(0xFFF0EEFF),
    this.gradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF675FAA), Color(0xFF53E4F3)],
    ),
    this.showShimmer = true,
    this.animationDuration = const Duration(milliseconds: 1100),
  });

  final double value;
  final double height;
  final Color trackColor;
  final LinearGradient gradient;
  final bool showShimmer;
  final Duration animationDuration;

  @override
  State<AnimatedGradientProgressBar> createState() =>
      _AnimatedGradientProgressBarState();
}

class _AnimatedGradientProgressBarState
    extends State<AnimatedGradientProgressBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmerController;

  void _startShimmerIfNeeded() {
    if (_shimmerController != null || !widget.showShimmer) {
      return;
    }

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void initState() {
    super.initState();
    _startShimmerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AnimatedGradientProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showShimmer != oldWidget.showShimmer) {
      if (widget.showShimmer) {
        _startShimmerIfNeeded();
      } else {
        _shimmerController?.dispose();
        _shimmerController = null;
      }
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedValue = widget.value.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clampedValue),
      duration: widget.animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: widget.trackColor),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: widget.gradient),
                  ),
                ),
                if (widget.showShimmer &&
                    animatedValue > 0 &&
                    _shimmerController != null)
                  AnimatedBuilder(
                    animation: _shimmerController!,
                    builder: (context, child) {
                      final shimmerX =
                          -1.5 + (_shimmerController!.value * 3);
                      return IgnorePointer(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: animatedValue,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(shimmerX - 0.25, 0),
                                end: Alignment(shimmerX + 0.25, 0),
                                colors: const [
                                  Colors.transparent,
                                  Color(0x55FFFFFF),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
