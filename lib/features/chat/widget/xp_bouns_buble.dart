import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class XpBonusBubble extends StatefulWidget {
  const XpBonusBubble({super.key});

  @override
  State<XpBonusBubble> createState() => _XpBonusBubbleState();
}

class _XpBonusBubbleState extends State<XpBonusBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
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
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FFF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '+2,400 Circle XP',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Cluster bonus activated · 6 zones owned',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFF66BB6A),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '⚡',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Color(0xFF66BB6A),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
