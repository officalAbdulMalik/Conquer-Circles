import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/chat/models/chat_model.dart';
import 'package:test_steps/features/chat/widget/avatar_tile.dart';
import 'package:test_steps/features/chat/widget/message_input_bar.dart';
import 'package:test_steps/features/chat/widget/quick_reaction_bar.dart';
import 'package:test_steps/features/chat/widget/raid_reply_bubble.dart';
import 'package:test_steps/features/chat/widget/recived_message_bublle.dart';
import 'package:test_steps/features/chat/widget/sent_message_bubble.dart';
import 'package:test_steps/features/chat/widget/typing_editor.dart';
import 'package:test_steps/features/chat/widget/xp_bouns_buble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

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
    Member(name: 'ShadowS', avatar: '🌙', score: '5.4k'),
    Member(name: 'intE', avatar: '🖥️', score: '7.8k', isOnline: true),
    Member(name: 'son', avatar: '🐊', score: '10.3k', isOnline: true),
  ];

  // Message list — using a sealed-like approach with type enum
  // Each item is either a ChatMessage or a special widget key
  // We use a list of dynamic and check type in build
  final List<dynamic> chatItems = [
    'xp_bonus',
    const ChatMessageModel(
      text: 'South Shore is under attack! DarkCircle is pushing hard 🤯',
      time: '9:14 AM',
      type: MessageType.sent,
    ),
    const ChatMessageModel(
      senderName: 'IronStrider',
      senderAvatar: '🐗',
      text: 'Already there. 2v1 but I\'m holding it 🔥',
      time: '9:15 AM',
      type: MessageType.received,
      replyPreview: 'You: South Shore is under attack! DarkCircl...',
      reactions: [
        Reaction(emoji: '⚡', count: 7),
        Reaction(emoji: '💪', count: 3),
      ],
      senderNameColor: AppColors.senderIronStrider,
    ),
    const ChatMessageModel(
      senderName: 'NeonPath',
      senderAvatar: '⚡',
      text: 'On the way, give me 4 mins ⚡',
      time: '9:16 AM',
      type: MessageType.received,
      senderNameColor: AppColors.senderNeonPath,
    ),
    'raid_repelled',
    const ChatMessageModel(
      text: 'LETS GOOO 🎉 IronStrider MVP no cap',
      time: '9:23 AM',
      type: MessageType.sent,
      reactions: [
        Reaction(emoji: '👏', count: 4),
        Reaction(emoji: '🔥', count: 3),
      ],
    ),
    'typing',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.black.withOpacity(0.08),
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
              children: const [
                Text(
                  'StormWalkers',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '6 online · 24 members',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11.5,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Color(0xFF333355)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF333355)),
            onPressed: () {},
          ),
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
              height: 80.sp,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: chatItems.length,
              itemBuilder: (context, i) {
                final item = chatItems[i];

                if (item == 'xp_bonus') {
                  return const XpBonusBubble();
                }

                if (item == 'raid_repelled') {
                  return const RaidRepelledBubble();
                }

                if (item == 'typing') {
                  return const TypingIndicator(
                    name: 'IronStrider',
                    avatarEmoji: '🐗',
                  );
                }

                final msg = item as ChatMessageModel;

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
          const MessageInputBar(),
          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
