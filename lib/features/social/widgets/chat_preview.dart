import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/chat/views/messages.dart';
import 'package:test_steps/features/social/mock_data/chat_messages_mock_data.dart';
import 'package:test_steps/features/social/models/chat_models.dart';
import 'package:test_steps/features/social/view/circle_comms_view.dart';
import 'package:test_steps/providers/circles_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// A card widget that displays a circle chat interface.
///
/// Allows users to view and send messages in a circle chat, with support for
/// unread counts, message bubbles, and input functionality.
///
/// Example usage:
/// ```dart
/// CircleChatCard(
///   circleTitle: 'My Circle',
///   unreadCount: 5,
///   myAvatarEmoji: '🦅',
///   onCollapse: () => collapseChat(),
/// )
/// ```
class CircleChatCard extends ConsumerStatefulWidget {
  /// Creates a [CircleChatCard].
  ///
  /// [circleTitle] - The title of the circle chat.
  /// [unreadCount] - Number of unread messages.
  /// [myAvatarEmoji] - Emoji for the user's avatar.
  /// [onCollapse] - Callback when the collapse button is tapped.
  const CircleChatCard({
    super.key,
    this.circleTitle = 'Circle Chat',
    this.unreadCount = 4,
    this.myAvatarEmoji = '🦅',
    this.onCollapse,
  });

  final String circleTitle;
  final int unreadCount;
  final String myAvatarEmoji;
  final VoidCallback? onCollapse;

  @override
  ConsumerState<CircleChatCard> createState() => _CircleChatCardState();
}

class _CircleChatCardState extends ConsumerState<CircleChatCard> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = List.from(sampleChatMessages);
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(String? circleId, String circleName) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (circleId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CircleCommsView(
            circleId: circleId,
            circleName: circleName,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      );
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          sender: MessageSender.me,
          timeLabel: 'just now',
        ),
      );
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);
    final currentCircle = circlesState.circles.isNotEmpty ? circlesState.circles.first : null;
    final circleId = currentCircle?['circle_id']?.toString();
    final circleName = currentCircle?['circles']?['name']?.toString() ?? widget.circleTitle;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            title: widget.circleTitle,
            unreadCount: widget.unreadCount,
            onCollapse: widget.onCollapse,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F6)),
          // Message list
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 220.h),
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shrinkWrap: true,
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(
                message: _messages[i],
                myAvatarEmoji: widget.myAvatarEmoji,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F6)),
          _InputBar(controller: _controller, hasText: _hasText, onSend: () => _send(circleId, circleName)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

/// Private widget for the chat card header.
class _Header extends StatelessWidget {
  /// Creates a [_Header].
  const _Header({
    required this.title,
    required this.unreadCount,
    this.onCollapse,
  });

  final String title;
  final int unreadCount;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.accentPurple,
            size: 18,
          ),
          8.horizontalSpace,
          Text(title, style: AppTextStyles.heading3),
          8.horizontalSpace,
          // Unread badge
          if (unreadCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.bubbleMe,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$unreadCount',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: onCollapse,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

/// Private widget for displaying a chat message bubble.
class _MessageBubble extends StatelessWidget {
  /// Creates a [_MessageBubble].
  const _MessageBubble({required this.message, required this.myAvatarEmoji});

  final ChatMessage message;
  final String myAvatarEmoji;

  bool get _isMe => message.sender == MessageSender.me;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: _isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Sender name (other only)
          if (!_isMe && message.senderName != null)
            Padding(
              padding: EdgeInsets.only(left: 44.w, bottom: 3.h),
              child: Text(
                message.senderName!,
                style: AppTextStyles.poppins(
                  size: 11.5,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w600,
                ),
              ),
            ),

          Row(
            mainAxisAlignment: _isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar (other only)
              if (!_isMe) ...[
                _Avatar(emoji: message.avatarEmoji ?? '?'),
                SizedBox(width: 8.w),
              ],

              // Bubble
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isMe ? AppColors.bubbleMe : AppColors.bubbleOther,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(_isMe ? 16.r : 4.r),
                      bottomRight: Radius.circular(_isMe ? 4.r : 16.r),
                    ),
                    boxShadow: _isMe
                        ? [
                            BoxShadow(
                              color: AppColors.bubbleMe.withValues(alpha: 0.30),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.poppins(
                      size: 14,
                      color: _isMe ? Colors.white : AppColors.textNavy,
                      weight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // My avatar (me side)
              if (_isMe) ...[
                SizedBox(width: 8.w),
                _Avatar(emoji: myAvatarEmoji, isMe: true),
              ],
            ],
          ),

          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              top: 4.h,
              left: _isMe ? 0 : 44.w,
              right: _isMe ? 44.w : 0,
            ),
            child: Text(
              message.timeLabel,
              style: AppTextStyles.poppins(
                size: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar circle
// ─────────────────────────────────────────────────────────────────────────────

/// Private widget for displaying a user avatar.
class _Avatar extends StatelessWidget {
  /// Creates an [_Avatar].
  const _Avatar({required this.emoji, this.isMe = false});

  final String emoji;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.accentPurple.withValues(alpha: 0.15)
            : AppColors.tabActiveBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: 15.sp)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────

/// Private widget for the message input bar.
class _InputBar extends StatelessWidget {
  /// Creates an [_InputBar].
  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: AppTextStyles.poppins(
                  size: 14,
                  color: AppColors.textNavy,
                ),
                decoration: InputDecoration(
                  hintText: 'Message your circle...',
                  hintStyle: AppTextStyles.poppins(
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: hasText
                  ? AppColors.bubbleMe
                  : AppColors.bubbleMe.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              boxShadow: hasText
                  ? [
                      BoxShadow(
                        color: AppColors.bubbleMe.withValues(alpha: 0.35),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: hasText ? onSend : null,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
