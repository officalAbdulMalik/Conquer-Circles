class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final bool isPremium;
  final bool hasSeasonPass;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.isPremium = false,
    this.hasSeasonPass = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? 'Unknown',
      email: json['email'],
      avatarUrl: json['avatar_url'],
      isPremium: json['is_premium'] ?? false,
      hasSeasonPass: json['has_season_pass'] ?? false,
    );
  }
}

class Invite {
  final String id;
  final String inviterId;
  final String inviteeId;
  final String? targetId;
  final String status;
  final DateTime createdAt;
  final String? inviterUsername;
  final String? inviteeUsername;

  Invite({
    required this.id,
    required this.inviterId,
    required this.inviteeId,
    this.targetId,
    required this.status,
    required this.createdAt,
    this.inviterUsername,
    this.inviteeUsername,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'],
      inviterId: json['inviter_id'],
      inviteeId: json['invitee_id'],
      targetId: json['target_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      inviterUsername: json['inviter']?['username'],
      inviteeUsername: json['invitee']?['username'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
