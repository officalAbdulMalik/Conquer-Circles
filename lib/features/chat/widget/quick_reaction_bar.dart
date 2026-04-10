import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class QuickReactionBar extends StatefulWidget {
  const QuickReactionBar({super.key});

  @override
  State<QuickReactionBar> createState() => _QuickReactionBarState();
}

class _QuickReactionBarState extends State<QuickReactionBar> {
  final List<String> _emojis = ['👍', '🔥', '💪', '🎉', '😂', '🤍'];
  int? _tappedIndex;

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _tappedIndex = index);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _tappedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ...List.generate(_emojis.length, (i) {
            final isTapped = _tappedIndex == i;
            return GestureDetector(
              onTap: () => _onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                margin: const EdgeInsets.only(right: 10),
                transform: Matrix4.identity()..scale(isTapped ? 1.35 : 1.0),
                transformAlignment: Alignment.center,
                child: Text(_emojis[i], style: const TextStyle(fontSize: 22)),
              ),
            );
          }),
          const Spacer(),
          Text(
            'Tap to add',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
