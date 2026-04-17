import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/circle_messages_provider.dart';

class CircleCommsView extends ConsumerStatefulWidget {
  final String circleId;
  final String circleName;
  const CircleCommsView({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  @override
  ConsumerState<CircleCommsView> createState() => _CircleCommsViewState();
}

class _CircleCommsViewState extends ConsumerState<CircleCommsView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(circleMessagesProvider(widget.circleId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.circleName} Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesState.isLoading && messagesState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messagesState.messages.isEmpty
                ? const Center(child: Text('No messages yet. Say hi!'))
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messagesState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = messagesState.messages[index];
                      final messageId = msg['id']?.toString();
                      final isMe = msg['user_id'] == currentUserId;
                      final senderName =
                          msg['sender_info']?['username'] ??
                          msg['profiles']?['username'] ??
                          'User';

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () {
                            final messageId = msg['id']?.toString();
                            if (messageId != null) {
                              _openReactionSheet(messageId);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF0D968B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF0D968B),
                                    ),
                                  ),
                                Text(
                                  msg['message'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if ((msg['reactions'] as List?)?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: (msg['reactions'] as List)
                                          .map<Widget>((reaction) {
                                        final reactionMap = Map<String, dynamic>.from(
                                          reaction as Map,
                                        );
                                        final emoji = reactionMap['emoji']?.toString() ?? '';
                                        final count = reactionMap['count'] ?? 0;
                                        final selected = reactionMap['selected'] == true;
                                        return GestureDetector(
                                          onTap: () {
                                            if (messageId != null) {
                                              ref
                                                  .read(
                                                    circleMessagesProvider(widget.circleId).notifier,
                                                  )
                                                  .toggleReaction(messageId, emoji);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? const Color(0xFF0D968B)
                                                  : const Color(0xFFF5F5FF),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  emoji,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: selected ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$count',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: selected ? Colors.white : const Color(0xFF7C6FCD),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0D968B)),
                  onPressed: () async {
                    final content = _messageController.text.trim();
                    if (content.isNotEmpty) {
                      _messageController.clear();
                      await ref
                          .read(
                            circleMessagesProvider(widget.circleId).notifier,
                          )
                          .sendMessage(content);
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          if (messagesState.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                messagesState.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _openReactionSheet(String messageId) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const emojis = ['👍', '🔥', '💪', '🎉', '😂', '🤍'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'React to message',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(
                            circleMessagesProvider(widget.circleId).notifier,
                          )
                          .toggleReaction(messageId, emoji);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Long press a message to choose a reaction, or tap a reaction chip to toggle it.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
