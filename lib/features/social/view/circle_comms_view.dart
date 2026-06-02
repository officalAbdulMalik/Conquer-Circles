import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/circle_messages_provider.dart';
import 'package:test_steps/widgets/shared/app_avatar_stack.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class CircleCommsView extends ConsumerStatefulWidget {
  const CircleCommsView({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  final String circleId;
  final String circleName;

  @override
  ConsumerState<CircleCommsView> createState() => _CircleCommsViewState();
}

class _CircleCommsViewState extends ConsumerState<CircleCommsView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(circleMessagesProvider(widget.circleId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final messages = messagesState.messages.isEmpty
        ? _previewMessages
        : messagesState.messages
              .map((row) => _chatMessageFromRow(row, currentUserId))
              .toList()
              .reversed
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: _ChatHeader(
                    title: widget.circleName.isEmpty
                        ? 'StromWalker Team'
                        : widget.circleName,
                    onBack: () => Navigator.maybePop(context),
                    onMenuTap: () {},
                  ),
                ),
                22.verticalSpace,
                Expanded(
                  child:
                      messagesState.isLoading && messagesState.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                          children: [
                            const _DayChip(label: 'Today'),
                            14.verticalSpace,
                            ...List.generate(messages.length, (index) {
                              return _ChatMessageBlock(
                                message: messages[index],
                              );
                            }),
                          ],
                        ),
                ),
                _ChatComposer(
                  controller: _messageController,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _CircleChatMessage _chatMessageFromRow(
    Map<String, dynamic> row,
    String? currentUserId,
  ) {
    final senderInfo = row['sender_info'] as Map<String, dynamic>?;
    final senderName =
        senderInfo?['username']?.toString() ??
        row['profiles']?['username']?.toString() ??
        'Member';
    final isMe = row['user_id']?.toString() == currentUserId;
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final time = createdAt == null
        ? ''
        : TimeOfDay.fromDateTime(createdAt.toLocal()).format(context);

    return _CircleChatMessage(
      sender: isMe ? 'You' : senderName,
      time: time,
      text: row['message']?.toString() ?? '',
      isMe: isMe,
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await ref
        .read(circleMessagesProvider(widget.circleId).notifier)
        .sendMessage(content);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.onBack,
    required this.onMenuTap,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            onBack();
          },
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: AppBorders.raised(),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        12.horizontalSpace,
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: AppColors.blueContiner,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/battery.png',
              width: 34.w,
              height: 34.w,
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.montserrat(
                  size: 16.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
              8.verticalSpace,
              const AppAvatarStack(
                emojis: ['👩', '👱', '🧑', '👨'],
                size: 25,
                overlap: 15,
                backgroundColor: AppColors.surface,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onMenuTap,
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppColors.textPrimary,
            size: 26.sp,
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Text(
          label,
          style: AppTextStyles.montserrat(
            size: 12.sp,
            color: AppColors.blueColor,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBlock extends StatelessWidget {
  const _ChatMessageBlock({required this.message});

  final _CircleChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 336.w),
            child: Container(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 11.h),
              decoration: BoxDecoration(
                color: message.isMe ? AppColors.blueColor : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: message.isMe ? null : AppBorders.raised(),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.montserrat(
                  size: 14.sp,
                  color: message.isMe ? Colors.white : AppColors.textPrimary,
                  weight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),
          8.verticalSpace,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${message.sender} .",
                style: AppTextStyles.montserrat(
                  size: 12.sp,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
              6.horizontalSpace,
              Text(
                message.time,
                style: AppTextStyles.montserrat(
                  size: 12.sp,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppTextInput(
                controller: controller,
                hintText: 'Type message',
                height: 52,
                borderRadius: 20,
                border: AppBorders.raised(),
                suffixIcon: Icon(
                  Icons.image_outlined,
                  color: AppColors.textPrimary,
                  size: 24.sp,
                ),
              ),
            ),
            10.horizontalSpace,
            InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: Container(
              padding: EdgeInsets.all(12.sp),
                decoration:  BoxDecoration(
                  color: AppColors.blueColor,
                  borderRadius: BorderRadius.circular(26.r),
                  border: AppBorders.raised(
                    color: AppColors.blueColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Image.asset('assets/images/send.png', width: 24.sp, height: 24.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleChatMessage {
  const _CircleChatMessage({
    required this.sender,
    required this.time,
    required this.text,
    this.isMe = false,
  });

  final String sender;
  final String time;
  final String text;
  final bool isMe;
}

const _previewMessages = [
  _CircleChatMessage(
    sender: 'Sarah',
    time: '11:33PM',
    text: 'Rival activity near Downtown sector again.',
  ),
  _CircleChatMessage(
    sender: 'Alex',
    time: '11:36PM',
    text: 'I’m heading there now. Should secure east border in 15 mins.',
  ),
  _CircleChatMessage(
    sender: 'Micheal',
    time: '11:39PM',
    text: 'Just captured +0.3 km² near Central Station 🔥',
  ),
  _CircleChatMessage(
    sender: 'You',
    time: '11:55PM',
    text: 'Nice. I’ll defend north side before they push further.',
    isMe: true,
  ),
  _CircleChatMessage(
    sender: 'Sarah',
    time: '12:07AM',
    text: 'Perfect. We only need +1.2 km² more for weekly mission.',
  ),
  _CircleChatMessage(
    sender: 'Alex',
    time: '12:29AM',
    text: 'Starting territory raid now ⚔',
  ),
  _CircleChatMessage(
    sender: 'Micheal',
    time: '12:41AM',
    text: 'Don’t forget to activate defense boost.',
  ),
];
