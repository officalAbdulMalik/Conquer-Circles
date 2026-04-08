import 'package:test_steps/features/social/models/chat_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample chat messages data
// ─────────────────────────────────────────────────────────────────────────────

final List<ChatMessage> sampleChatMessages = [
  const ChatMessage(
    text: 'I defended East Heights solo last night 🤩',
    sender: MessageSender.other,
    timeLabel: '45s ago',
    avatarEmoji: '⚡',
    senderName: 'NeonPath',
  ),
  const ChatMessage(
    text: "GG team! Season ends in 3 days, let's push!",
    sender: MessageSender.me,
    timeLabel: 'just now',
  ),
];