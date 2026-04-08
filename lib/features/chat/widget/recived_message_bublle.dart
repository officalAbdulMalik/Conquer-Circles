import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/chat/models/chat_model.dart';
import 'package:test_steps/features/chat/widget/reaction_row.dart';


class ReceivedMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final String avatarEmoji;
  const ReceivedMessageBubble({
    super.key,
    required this.message,
    required this.avatarEmoji,
  });

  @override
  State<ReceivedMessageBubble> createState() => _ReceivedMessageBubbleState();
}

class _ReceivedMessageBubbleState extends State<ReceivedMessageBubble>
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
      begin: const Offset(-0.3, 0),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender name
              if (widget.message.senderName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 2),
                  child: Text(
                    widget.message.senderName!,
                    style: TextStyle(
                      color: widget.message.senderNameColor ??
                          AppColors.senderIronStrider,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEEEEF8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.avatarEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  // Bubble
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.receivedBubble,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply preview
                          if (widget.message.replyPreview != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.purple,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.reply,
                                      size: 13, color: AppColors.purple),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.message.replyPreview!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF888888),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Text(
                            widget.message.text,
                            style: const TextStyle(
                              color: AppColors.receivedText,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 3),
                child: Row(
                  children: [
                    Text(
                      widget.message.time,
                      style: const TextStyle(
                        color: AppColors.timeText,
                        fontSize: 11,
                      ),
                    ),
                    if (widget.message.reactions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ReactionRow(reactions: widget.message.reactions),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}