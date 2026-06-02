class CircleDetailMetric {
  const CircleDetailMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;
}

class CircleLeaderboardMember {
  const CircleLeaderboardMember({
    required this.name,
    required this.rank,
    required this.score,
    required this.avatar,
    this.isCurrentUser = false,
    this.medal,
  });

  final String name;
  final String rank;
  final int score;
  final String avatar;
  final bool isCurrentUser;
  final String? medal;
}

class CircleActivityItem {
  const CircleActivityItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class CircleJoinRequest {
  const CircleJoinRequest({
    required this.id,
    required this.name,
    required this.avatar,
  });

  final String id;
  final String name;
  final String avatar;
}
