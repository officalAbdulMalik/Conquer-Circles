/// Enum representing the sender of a chat message.
enum MessageSender { other, me }

/// Model class for a chat message.
class ChatMessage {
  /// Creates a [ChatMessage].
  const ChatMessage({
    required this.text,
    required this.sender,
    required this.timeLabel,
    this.avatarEmoji,
    this.senderName,
  });

  /// The text content of the message.
  final String text;

  /// The sender of the message.
  final MessageSender sender;

  /// The time label for when the message was sent.
  final String timeLabel;

  /// The emoji for the avatar, shown for other's messages.
  final String? avatarEmoji;

  /// The name of the sender, shown for other's messages.
  final String? senderName;
}