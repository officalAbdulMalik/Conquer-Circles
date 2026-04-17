import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/chat/models/chat_model.dart';
import 'package:test_steps/features/chat/widget/avatar_tile.dart';
import 'package:test_steps/features/chat/widget/message_input_bar.dart';
import 'package:test_steps/features/chat/widget/quick_reaction_bar.dart';
import 'package:test_steps/features/chat/widget/recived_message_bublle.dart';
import 'package:test_steps/features/chat/widget/sent_message_bubble.dart';
import 'package:test_steps/providers/circle_messages_provider.dart';
import 'package:test_steps/providers/circles_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  final List<Member> members = const [
    Member(
      name: 'You',
      avatar: '🦅',
      score: '8.5k',
      isOnline: true,
      isMe: true,
    ),
    Member(name: 'IronStride', avatar: '🐗', score: '12k', isOnline: true),
    Member(name: 'NeonPatf', avatar: '⚡', score: '6.2k', isOnline: true),
    Member(name: 'TitanWalk', avatar: '🛡️', score: '9.1k', isOnline: true),
    Member(name: 'SwiftBlaz', avatar: '🔥', score: '14k', isOnline: true),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ChatMessageModel _mapMessage(Map<String, dynamic> row, String? currentUserId) {
    final senderInfo = row['sender_info'] as Map<String, dynamic>?;
    final username = senderInfo?['username']?.toString() ?? 'Anonymous';
    final avatar = senderInfo?['avatar_url']?.toString();
    final avatarEmoji = avatar?.isNotEmpty == true ? avatar : username.isNotEmpty ? username[0] : '👤';
    final createdAt = row['created_at']?.toString() ?? '';
    final timeLabel = createdAt.isNotEmpty
        ? DateTime.tryParse(createdAt)
            ?.toLocal()
            .toString()
            .split(' ')[1]
            .split('.')
            .first
        : '';
    final isMe = row['user_id']?.toString() == currentUserId;
    final reactions = <Reaction>[];
    if (row['reactions'] is List) {
      for (final rawReaction in row['reactions'] as List) {
        if (rawReaction is Map) {
          final emoji = rawReaction['emoji']?.toString() ?? '';
          final count = rawReaction['count'] is int
              ? rawReaction['count'] as int
              : int.tryParse('${rawReaction['count']}') ?? 0;
          if (emoji.isNotEmpty) {
            reactions.add(Reaction(emoji: emoji, count: count));
          }
        }
      }
    }

    return ChatMessageModel(
      senderName: isMe ? null : username,
      senderAvatar: isMe ? null : avatarEmoji,
      text: row['message']?.toString() ?? '',
      time: timeLabel??'',
      type: isMe ? MessageType.sent : MessageType.received,
      reactions: reactions,
      senderNameColor: AppColors.senderIronStrider,
    );
  }

  Future<void> _sendMessage(String circleId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    await ref.read(circleMessagesProvider(circleId).notifier).sendMessage(content);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);
    final currentCircle = circlesState.circles.isNotEmpty ? circlesState.circles.first : null;
    final circleId = currentCircle?['circle_id']?.toString();
    final circleName = currentCircle?['circles']?['name']?.toString() ?? 'Circle Chat';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (circleId == null || circleId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Text('Circle Chat', style: AppTextStyles.heading3.copyWith(fontSize: 18.sp)),
        ),
        body: const Center(
          child: Text('No active circle found. Join or create a circle first.'),
        ),
      );
    }

    final messagesState = ref.watch(circleMessagesProvider(circleId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEEEEF8),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 22)),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circleName,
                  style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                ),
                Text(
                  '${circlesState.circles.length} circle member(s)',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF333355)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 90.sp,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.sp),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) => SizedBox(
                  width: 52,
                  child: MemberAvatarTile(member: members[i]),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: messagesState.isLoading && messagesState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messagesState.messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hi!'))
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messagesState.messages.length,
                        itemBuilder: (context, i) {
                          final row = messagesState.messages[i];
                          final msg = _mapMessage(row, currentUserId);
                          if (msg.type == MessageType.sent) {
                            return SentMessageBubble(message: msg);
                          }
                          return ReceivedMessageBubble(
                            message: msg,
                            avatarEmoji: msg.senderAvatar ?? '👤',
                          );
                        },
                      ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const QuickReactionBar(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          MessageInputBar(
            controller: _messageController,
            onSend: () => _sendMessage(circleId),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
