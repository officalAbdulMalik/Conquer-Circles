import 'package:flutter/material.dart';

class GuildStat {
  const GuildStat({
    required this.icon,
    required this.value,
    required this.label,
  });
  final Widget icon;
  final String value;
  final String label;
}

class GuildMember {
  const GuildMember({
    required this.avatarEmoji,
    required this.bgColor,
    this.isOnline = false,
  });
  final String avatarEmoji;
  final Color bgColor;
  final bool isOnline;
}
