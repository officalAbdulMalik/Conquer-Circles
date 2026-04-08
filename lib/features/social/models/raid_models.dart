enum RaidStatus { activeAttack, repelled, zoneLost }

class RaidAlert {
  const RaidAlert({
    required this.attacker,
    required this.target,
    required this.status,
    required this.timeAgo,
    required this.iconEmoji,
  });

  final String attacker;
  final String target;
  final RaidStatus status;
  final String timeAgo;
  final String iconEmoji;
}
