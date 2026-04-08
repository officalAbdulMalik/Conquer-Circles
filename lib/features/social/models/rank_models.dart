import 'package:flutter/material.dart';

class SpecialRank {
  const SpecialRank({
    required this.cardColor,
    required this.iconEmoji,
    required this.title,
    required this.titleColor,
    required this.playerEmoji,
    required this.playerName,
    required this.statValue,
    required this.statColor,
    required this.statDescription,
  });

  final Color cardColor;
  final String iconEmoji;
  final String title;
  final Color titleColor;
  final String playerEmoji;
  final String playerName;
  final String statValue;
  final Color statColor;
  final String statDescription;
}
