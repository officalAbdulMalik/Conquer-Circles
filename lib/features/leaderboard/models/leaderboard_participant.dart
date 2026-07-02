class LeaderboardParticipant {
  const LeaderboardParticipant({
    required this.userId,
    required this.name,
    required this.score,
    required this.rank,
    this.avatarUrl,
    this.avatarAsset,
    this.avatarEmoji,
    this.medal,
    this.isCurrentUser = false,
    this.territoryTiles = 0,
    this.totalSteps = 0,
    this.raidsWon = 0,
    this.territoryEnergy = 0,
    this.attacksStarted = 0,
    this.defensesWon = 0,
    this.activeWalkDays = 0,
  });

  final String userId;
  final String name;
  final int score;
  final int rank;
  final String? avatarUrl;
  final String? avatarAsset;
  final String? avatarEmoji;
  final String? medal;
  final bool isCurrentUser;
  final int territoryTiles;
  final int totalSteps;
  final int raidsWon;
  final int territoryEnergy;
  final int attacksStarted;
  final int defensesWon;
  final int activeWalkDays;

  int scoreFor(LeaderboardMetric metric) {
    switch (metric) {
      case LeaderboardMetric.territoryTiles:
        return territoryTiles;
      case LeaderboardMetric.totalSteps:
        return totalSteps;
      case LeaderboardMetric.raidsWon:
        return raidsWon;
      case LeaderboardMetric.territoryEnergy:
        return territoryEnergy;
    }
  }

  LeaderboardParticipant copyWith({int? score, int? rank, String? medal}) {
    return LeaderboardParticipant(
      userId: userId,
      name: name,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      avatarUrl: avatarUrl,
      avatarAsset: avatarAsset,
      avatarEmoji: avatarEmoji,
      medal: medal ?? this.medal,
      isCurrentUser: isCurrentUser,
      territoryTiles: territoryTiles,
      totalSteps: totalSteps,
      raidsWon: raidsWon,
      territoryEnergy: territoryEnergy,
      attacksStarted: attacksStarted,
      defensesWon: defensesWon,
      activeWalkDays: activeWalkDays,
    );
  }
}

enum LeaderboardMetric {
  territoryTiles,
  totalSteps,
  raidsWon,
  territoryEnergy;

  String get label {
    switch (this) {
      case LeaderboardMetric.territoryTiles:
        return 'Tiles';
      case LeaderboardMetric.totalSteps:
        return 'Steps';
      case LeaderboardMetric.raidsWon:
        return 'Raids';
      case LeaderboardMetric.territoryEnergy:
        return 'Energy';
    }
  }
}

class LeaderboardSeason {
  const LeaderboardSeason({
    this.id,
    this.name = 'Current Season',
    this.startedAt,
    this.endsAt,
  });

  final String? id;
  final String name;
  final DateTime? startedAt;
  final DateTime? endsAt;
}

class LeaderboardSpecialRankings {
  const LeaderboardSpecialRankings({
    this.mostAggressive,
    this.bestDefender,
    this.mostConsistent,
  });

  final LeaderboardParticipant? mostAggressive;
  final LeaderboardParticipant? bestDefender;
  final LeaderboardParticipant? mostConsistent;
}

class LeaderboardData {
  const LeaderboardData({
    required this.season,
    required this.participants,
    required this.specialRankings,
  });

  final LeaderboardSeason season;
  final List<LeaderboardParticipant> participants;
  final LeaderboardSpecialRankings specialRankings;
}
