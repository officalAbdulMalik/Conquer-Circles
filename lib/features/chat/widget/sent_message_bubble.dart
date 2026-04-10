import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/chat/models/chat_model.dart';
import 'package:test_steps/features/chat/widget/reaction_row.dart';

class SentMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  const SentMessageBubble({super.key, required this.message});

  @override
  State<SentMessageBubble> createState() => _SentMessageBubbleState();
}

class _SentMessageBubbleState extends State<SentMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sentBubble,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.message.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.sentText,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                widget.message.time,
                style: const TextStyle(color: AppColors.timeText, fontSize: 11),
              ),
              if (widget.message.reactions.isNotEmpty) ...[
                const SizedBox(height: 4),
                ReactionRow(reactions: widget.message.reactions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
