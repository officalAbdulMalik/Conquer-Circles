import 'package:flutter/material.dart';

/// Enum representing the join status of a circle.
enum JoinStatus { request, join, full }

/// Model class for a circle tag.
class CircleTag {
  /// Creates a [CircleTag].
  const CircleTag({required this.label, required this.color, this.icon});

  /// The label text of the tag.
  final String label;

  /// The color of the tag.
  final Color color;

  /// Optional icon for the tag.
  final String? icon;
}

/// Model class for circle data.
class CircleData {
  /// Creates a [CircleData].
  const CircleData({
    required this.name,
    required this.quote,
    required this.logoEmoji,
    required this.logoBgColor,
    required this.cardBgColor,
    required this.rank,
    required this.rankTrend,
    required this.members,
    required this.maxMembers,
    required this.zones,
    required this.wins,
    required this.xp,
    required this.tags,
    required this.memberEmojis,
    required this.joinStatus,
    required this.joinColor,
    this.badge,
    this.badgeColor,
  });

  /// The name of the circle.
  final String name;

  /// The quote of the circle.
  final String quote;

  /// The emoji for the logo.
  final String logoEmoji;

  /// The background color for the logo.
  final Color logoBgColor;

  /// The background color for the card.
  final Color cardBgColor;

  /// The rank of the circle.
  final int rank;

  /// The rank trend (1 up, -1 down, 0 neutral).
  final int rankTrend;

  /// The number of members.
  final int members;

  /// The maximum number of members.
  final int maxMembers;

  /// The number of zones.
  final int zones;

  /// The number of wins.
  final int wins;

  /// The XP as a string.
  final String xp;

  /// The list of tags.
  final List<CircleTag> tags;

  /// The list of member emojis.
  final List<String> memberEmojis;

  /// The join status.
  final JoinStatus joinStatus;

  /// The color for the join button.
  final Color joinColor;

  /// Optional badge text.
  final String? badge;

  /// Optional badge color.
  final Color? badgeColor;
}