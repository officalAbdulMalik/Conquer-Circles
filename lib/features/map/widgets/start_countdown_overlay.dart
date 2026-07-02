import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class StartCountdownOverlay extends StatefulWidget {
  const StartCountdownOverlay({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  State<StartCountdownOverlay> createState() => _StartCountdownOverlayState();
}

class _StartCountdownOverlayState extends State<StartCountdownOverlay> {
  static const _labels = ['3', '2', '1', 'GO'];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_index == _labels.length - 1) {
        _timer?.cancel();
        widget.onComplete();
        return;
      }
      if (mounted) setState(() => _index += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: const Color(0xFF202B3B),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.82, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  key: ValueKey(_labels[_index]),
                  children: [
                    Transform.translate(
                      offset: Offset(-3.w, 14.h),
                      child: Text(
                        _labels[_index],
                        style: _countdownStyle(color: Colors.transparent)
                            .copyWith(
                              shadows: const [
                                Shadow(
                                  color: Colors.white,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                      ),
                    ),
                    Text(
                      _labels[_index],
                      style: _countdownStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 28.h,
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.montserrat(
                      size: 16.sp,
                      color: AppColors.blueColor,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _countdownStyle({required Color color}) {
    return AppTextStyles.poppins(
      size: _labels[_index] == 'GO' ? 112.sp : 170.sp,
      color: color,
      weight: FontWeight.w800,
      height: 1,
    );
  }
}
