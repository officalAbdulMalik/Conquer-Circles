import 'package:flutter/material.dart';
import 'package:test_steps/features/chat/models/chat_model.dart';

class ReactionRow extends StatefulWidget {
  final List<Reaction> reactions;
  const ReactionRow({super.key, required this.reactions});

  @override
  State<ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends State<ReactionRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.reactions.length * 80),
    );
    _animations = List.generate(widget.reactions.length, (i) {
      final start = i * 0.2;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.elasticOut),
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.reactions.length, (i) {
        final r = widget.reactions[i];
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ScaleTransition(
            scale: _animations[i],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DEFF), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${r.count}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C6FCD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}