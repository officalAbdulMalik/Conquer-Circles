import 'package:flutter/material.dart';

enum CircleJoinRequestStatus { pending, accepted, rejected, unknown }

class CircleMemberModel {
  const CircleMemberModel({
    required this.userId,
    required this.name,
    this.username,
    this.avatarUrl,
    this.role,
    this.xp = 0,
    this.level = 1,
    this.attackEnergy = 0,
    this.steps = 0,
    this.territories = 0,
    this.raidsWon = 0,
  });

  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? role;
  final int xp;
  final int level;
  final int attackEnergy;
  final int steps;
  final int territories;
  final int raidsWon;

  factory CircleMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = _map(json['profiles']);
    final source = profile.isEmpty ? json : {...profile, ...json};
    final username = _text(source['username']);
    final name =
        _firstText([
          source['full_name'],
          source['display_name'],
          username,
          source['name'],
        ]) ??
        'Circle member';

    return CircleMemberModel(
      userId: _text(source['user_id']) ?? _text(source['id']) ?? '',
      name: name,
      username: username,
      avatarUrl: _text(source['avatar_url']),
      role: _text(source['role']),
      xp: _integer(source['xp']),
      level: _integer(source['level'], fallback: 1),
      attackEnergy: _integer(source['attack_energy']),
      steps: _integer(source['steps']),
      territories: _integer(source['territories']),
      raidsWon: _integer(source['raids_won']),
    );
  }
}

class CircleModel {
  const CircleModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.inviteCode,
    this.imageUrl,
    this.isPrivate = false,
    this.isActive = true,
    this.isMember = false,
    this.createdByMe = false,
    this.memberCount = 0,
    this.maxMembers = 25,
    this.minMembers = 0,
    this.territories = 0,
    this.raidsWon = 0,
    this.rank = 0,
    this.rankTrend = 0,
    this.joinRequestStatus,
    this.members = const [],
    this.membershipRole,
  });

  final String id;
  final String name;
  final String? ownerId;
  final String? inviteCode;
  final String? imageUrl;
  final bool isPrivate;
  final bool isActive;
  final bool isMember;
  final bool createdByMe;
  final int memberCount;
  final int maxMembers;
  final int minMembers;
  final int territories;
  final int raidsWon;
  final int rank;
  final int rankTrend;
  final String? joinRequestStatus;
  final List<CircleMemberModel> members;
  final String? membershipRole;

  bool get isFull => memberCount >= maxMembers;
  bool get hasPendingJoinRequest => joinRequestStatus == 'pending';

  CircleModel copyWith({
    String? joinRequestStatus,
    int? memberCount,
    List<CircleMemberModel>? members,
  }) {
    return CircleModel(
      id: id,
      name: name,
      ownerId: ownerId,
      inviteCode: inviteCode,
      imageUrl: imageUrl,
      isPrivate: isPrivate,
      isActive: isActive,
      isMember: isMember,
      createdByMe: createdByMe,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers,
      minMembers: minMembers,
      territories: territories,
      raidsWon: raidsWon,
      rank: rank,
      rankTrend: rankTrend,
      joinRequestStatus: joinRequestStatus ?? this.joinRequestStatus,
      members: members ?? this.members,
      membershipRole: membershipRole,
    );
  }

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    final nestedCircle = _map(json['circles']);
    final source = nestedCircle.isEmpty ? json : {...json, ...nestedCircle};
    final rawMembers = source['member_profiles'] ?? source['leaderboard'];
    final members = _list(
      rawMembers,
    ).map((row) => CircleMemberModel.fromJson(_map(row))).toList();
    final memberCount =
        _nullableInteger(source['member_count']) ??
        _nullableInteger(source['members']) ??
        members.length;

    return CircleModel(
      id:
          _text(source['id']) ??
          _text(json['circle_id']) ??
          _text(source['circle_id']) ??
          '',
      name: _text(source['name']) ?? 'Unnamed Circle',
      ownerId: _text(source['owner_id']),
      inviteCode: _text(source['invite_code']),
      imageUrl: _text(source['image_url']) ?? _text(source['icon_url']),
      isPrivate: _boolean(source['is_private']),
      isActive: _boolean(source['is_active'], fallback: true),
      isMember: _boolean(
        source['is_member'],
        fallback: nestedCircle.isNotEmpty,
      ),
      createdByMe: _boolean(source['created_by_me']),
      memberCount: memberCount,
      maxMembers: _integer(source['max_members'], fallback: 25),
      minMembers: _integer(source['min_members']),
      territories: _integer(source['territories']),
      raidsWon: _integer(source['raids_won']),
      rank: _integer(source['rank']),
      rankTrend: _integer(source['rank_trend']),
      joinRequestStatus: _text(source['join_request_status']),
      members: members,
      membershipRole: _text(json['role']),
    );
  }
}

class CircleDetailsModel {
  const CircleDetailsModel({
    required this.circle,
    this.members = const [],
    this.recentMessages = const [],
    this.raidAlerts = const [],
  });

  final CircleModel circle;
  final List<CircleMemberModel> members;
  final List<Map<String, dynamic>> recentMessages;
  final List<Map<String, dynamic>> raidAlerts;

  factory CircleDetailsModel.fromJson(Map<String, dynamic> json) {
    final members = _list(
      json['leaderboard'],
    ).map((row) => CircleMemberModel.fromJson(_map(row))).toList();
    final circleJson = _map(json['circle']);

    return CircleDetailsModel(
      circle: CircleModel.fromJson({
        ...circleJson,
        'member_count':
            circleJson['member_count'] ??
            circleJson['members'] ??
            members.length,
        'leaderboard': members
            .map(
              (member) => {
                'user_id': member.userId,
                'full_name': member.name,
                'username': member.username,
                'avatar_url': member.avatarUrl,
                'role': member.role,
              },
            )
            .toList(),
      }),
      members: members,
      recentMessages: _list(json['recent_messages']).map(_map).toList(),
      raidAlerts: _list(json['raid_alerts']).map(_map).toList(),
    );
  }
}

class CircleJoinRequestModel {
  const CircleJoinRequestModel({
    required this.id,
    required this.circleId,
    required this.requesterId,
    required this.requesterName,
    required this.circleName,
    this.avatarUrl,
    this.status = CircleJoinRequestStatus.unknown,
    this.createdAt,
  });

  final String id;
  final String circleId;
  final String requesterId;
  final String requesterName;
  final String circleName;
  final String? avatarUrl;
  final CircleJoinRequestStatus status;
  final DateTime? createdAt;

  factory CircleJoinRequestModel.fromJson(Map<String, dynamic> json) {
    final requester = _map(json['requester']);
    final circle = _map(json['circle']);
    return CircleJoinRequestModel(
      id: _text(json['id']) ?? '',
      circleId: _text(json['circle_id']) ?? _text(circle['id']) ?? '',
      requesterId: _text(json['requester_id']) ?? '',
      requesterName:
          _firstText([
            requester['full_name'],
            requester['username'],
            json['full_name'],
            json['username'],
          ]) ??
          'Circle player',
      circleName: _text(circle['name']) ?? 'Circle',
      avatarUrl: _text(requester['avatar_url']) ?? _text(json['avatar_url']),
      status: _requestStatus(json['status']),
      createdAt: DateTime.tryParse(_text(json['created_at']) ?? ''),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text?.isNotEmpty == true ? text : null;
}

String? _firstText(List<dynamic> values) {
  for (final value in values) {
    final text = _text(value);
    if (text != null) return text;
  }
  return null;
}

int _integer(dynamic value, {int fallback = 0}) =>
    _nullableInteger(value) ?? fallback;

int? _nullableInteger(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

CircleJoinRequestStatus _requestStatus(dynamic value) {
  return switch (value?.toString().toLowerCase()) {
    'pending' => CircleJoinRequestStatus.pending,
    'accepted' => CircleJoinRequestStatus.accepted,
    'rejected' => CircleJoinRequestStatus.rejected,
    _ => CircleJoinRequestStatus.unknown,
  };
}

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
