import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class RaidRepelledBubble extends StatefulWidget {
  const RaidRepelledBubble({super.key});

  @override
  State<RaidRepelledBubble> createState() => _RaidRepelledBubbleState();
}

class _RaidRepelledBubbleState extends State<RaidRepelledBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF81C784), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF81C784),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '🛡️',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 16),
                  ),
                ),
              ),
              10.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raid Repelled! 🛡️',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'IronStrider defended South Shore successfully',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFF43A047),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.check, color: Color(0xFF81C784), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
