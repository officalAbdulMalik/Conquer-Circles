import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/providers/circle_messages_provider.dart';
import 'package:test_steps/widgets/shared/app_avatar_stack.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class CircleCommsView extends ConsumerStatefulWidget {
  const CircleCommsView({
    super.key,
    required this.circleId,
    required this.circleName,
    required this.members,
  });

  final String circleId;
  final String circleName;
  final List<CircleLeaderboardMember> members;

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
    final messages = messagesState.messages
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
                    members: widget.members,
                    onBack: () => Navigator.maybePop(context),
                    onMenuTap: () {},
                  ),
                ),
                22.verticalSpace,
                Expanded(
                  child:
                      messagesState.isLoading && messagesState.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : messagesState.error != null &&
                            messagesState.messages.isEmpty
                      ? _MessagesLoadError(
                          message: messagesState.error!,
                          onRetry: () => ref
                              .read(
                                circleMessagesProvider(
                                  widget.circleId,
                                ).notifier,
                              )
                              .refreshMessages(),
                        )
                      : ListView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                          children: [
                            const _DayChip(label: 'Today'),
                            14.verticalSpace,
                            if (messages.isEmpty)
                              const _EmptyMessages()
                            else
                              ...List.generate(messages.length, (index) {
                                return _ChatMessageBlock(
                                  message: messages[index],
                                  onLongPress: messages[index].isMe
                                      ? () =>
                                            _showMessageActions(messages[index])
                                      : null,
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
      id: row['id']?.toString() ?? '',
      sender: isMe ? 'You' : senderName,
      time: time,
      text: row['message']?.toString() ?? '',
      isMe: isMe,
      isEdited: row['edited_at'] != null,
    );
  }

  Future<void> _showMessageActions(_CircleChatMessage message) async {
    if (!message.isMe || message.id.isEmpty || message.id.startsWith('temp_')) {
      return;
    }

    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MessageActionsSheet(),
    );
    if (!mounted || action == null) return;

    if (action == _MessageAction.edit) {
      await _showEditMessageDialog(message);
      return;
    }

    final response = await ref
        .read(circleMessagesProvider(widget.circleId).notifier)
        .deleteMessage(message.id);
    if (!mounted || response['success'] == true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['error']?.toString() ?? 'Could not delete message',
        ),
      ),
    );
  }

  Future<void> _showEditMessageDialog(_CircleChatMessage message) async {
    final editedText = await showDialog<String>(
      context: context,
      builder: (context) => _EditMessageDialog(initialText: message.text),
    );
    if (!mounted || editedText == null || editedText == message.text) return;

    final response = await ref
        .read(circleMessagesProvider(widget.circleId).notifier)
        .editMessage(message.id, editedText);
    if (!mounted || response['success'] == true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['error']?.toString() ?? 'Could not edit message',
        ),
      ),
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
    required this.members,
    required this.onBack,
    required this.onMenuTap,
  });

  final String title;
  final List<CircleLeaderboardMember> members;
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
              AppAvatarStack(
                emojis: members.take(4).map((member) => member.avatar).toList(),
                imageUrls: members
                    .take(4)
                    .map((member) => member.avatarUrl)
                    .toList(),
                labels: members.take(4).map((member) => member.name).toList(),
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
  const _ChatMessageBlock({required this.message, this.onLongPress});

  final _CircleChatMessage message;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: ConstrainedBox(
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
                message.isEdited ? '${message.time} · Edited' : message.time,
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

enum _MessageAction { edit, delete }

class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initialText});

  final String initialText;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Message'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Message'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MessageActionsSheet extends StatelessWidget {
  const _MessageActionsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: AppBorders.raised(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MessageActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Message',
              onTap: () => Navigator.pop(context, _MessageAction.edit),
            ),
            Divider(height: 1, color: AppColors.borderColor),
            _MessageActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: const Color(0xFFFF3B4E),
              onTap: () => Navigator.pop(context, _MessageAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Icon(icon, color: color, size: 25.sp),
            ),
            12.horizontalSpace,
            Text(
              label,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: color,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 48.h),
      child: Center(
        child: Text(
          'No messages yet',
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: AppColors.textSecondary,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessagesLoadError extends StatelessWidget {
  const _MessagesLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Messages could not be loaded',
              style: AppTextStyles.montserrat(
                size: 16.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            8.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 12.sp,
                color: AppColors.textSecondary,
                weight: FontWeight.w400,
              ),
            ),
            12.verticalSpace,
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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
                decoration: BoxDecoration(
                  color: AppColors.blueColor,
                  borderRadius: BorderRadius.circular(26.r),
                  border: AppBorders.raised(
                    color: AppColors.blueColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Image.asset(
                  'assets/images/send.png',
                  width: 24.sp,
                  height: 24.sp,
                ),
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
    required this.id,
    required this.sender,
    required this.time,
    required this.text,
    this.isMe = false,
    this.isEdited = false,
  });

  final String id;
  final String sender;
  final String time;
  final String text;
  final bool isMe;
  final bool isEdited;
}
