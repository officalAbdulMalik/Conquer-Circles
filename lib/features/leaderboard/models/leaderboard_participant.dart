class LeaderboardParticipant {
  const LeaderboardParticipant({
    required this.name,
    required this.score,
    required this.rank,
    this.avatarAsset,
    this.avatarEmoji,
    this.medal,
    this.isCurrentUser = false,
  });

  final String name;
  final int score;
  final int rank;
  final String? avatarAsset;
  final String? avatarEmoji;
  final String? medal;
  final bool isCurrentUser;
}
