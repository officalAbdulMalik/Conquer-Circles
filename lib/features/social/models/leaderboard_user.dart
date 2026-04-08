import 'package:flutter/material.dart';

class LeaderboardUser {
  const LeaderboardUser({
    required this.rank,
    required this.username,
    required this.score,
    required this.progressValue,
    required this.avatarEmoji,
    required this.avatarBgColor,
    this.badgeEmoji,
    this.isOnline = false,
  });

  final int rank;
  final String username;
  final int score;
  final double progressValue; // 0.0 – 1.0
  final String avatarEmoji;
  final Color avatarBgColor;
  final String? badgeEmoji;
  final bool isOnline;
}
