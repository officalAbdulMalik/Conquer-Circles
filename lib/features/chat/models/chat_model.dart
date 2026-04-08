import 'package:flutter/material.dart';

enum MessageType { sent, received, system, xpBonus, raidEvent }

class Reaction {
  final String emoji;
  final int count;
  const Reaction({required this.emoji, required this.count});
}

class ChatMessageModel {
  final String? senderName;
  final String? senderAvatar; // emoji or asset path
  final String text;
  final String time;
  final MessageType type;
  final List<Reaction> reactions;
  final String? replyPreview;
  final Color? senderNameColor;

  const ChatMessageModel({
    this.senderName,
    this.senderAvatar,
    required this.text,
    required this.time,
    required this.type,
    this.reactions = const [],
    this.replyPreview,
    this.senderNameColor,
  });
}

class Member {
  final String name;
  final String avatar; // emoji
  final String score;
  final bool isOnline;
  final bool isMe;

  const Member({
    required this.name,
    required this.avatar,
    required this.score,
    this.isOnline = false,
    this.isMe = false,
  });
}