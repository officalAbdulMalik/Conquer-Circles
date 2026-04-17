import 'badge_model.dart';

class ProfileDataModel {
  final ProfileInfo profile;
  final TotalStats stats;
  final AnalyticsData analytics;
  final List<BadgeModel> badges;

  ProfileDataModel({
    required this.profile,
    required this.stats,
    required this.analytics,
    required this.badges,
  });

  factory ProfileDataModel.fromJson(Map<String, dynamic> json) {
    return ProfileDataModel(
      profile: ProfileInfo.fromJson(json['profile'] as Map<String, dynamic>),
      stats: TotalStats.fromJson(json['stats'] as Map<String, dynamic>),
      analytics: AnalyticsData.fromJson(json['analytics'] as Map<String, dynamic>),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ProfileDataModel copyWith({
    ProfileInfo? profile,
    TotalStats? stats,
    AnalyticsData? analytics,
    List<BadgeModel>? badges,
  }) {
    return ProfileDataModel(
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      analytics: analytics ?? this.analytics,
      badges: badges ?? this.badges,
    );
  }
}

class ProfileInfo {
  final String username;
  final int level;
  final int xp;
  final int dailyStreak;
  final bool notificationsEnabled;
  final DateTime? createdAt;

  ProfileInfo({
    required this.username,
    required this.level,
    required this.xp,
    required this.dailyStreak,
    required this.notificationsEnabled,
    this.createdAt,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      username: json['username'] as String? ?? 'User',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      dailyStreak: json['daily_streak'] as int? ?? 0,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  ProfileInfo copyWith({
    String? username,
    int? level,
    int? xp,
    int? dailyStreak,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return ProfileInfo(
      username: username ?? this.username,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TotalStats {
  final int totalSteps;
  final int totalCalories;
  final double totalDistanceKm;

  TotalStats({
    required this.totalSteps,
    required this.totalCalories,
    required this.totalDistanceKm,
  });

  factory TotalStats.fromJson(Map<String, dynamic> json) {
    return TotalStats(
      totalSteps: json['total_steps'] as int? ?? 0,
      totalCalories: json['total_calories'] as int? ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AnalyticsData {
  final List<ChartPoint> weekly;
  final List<ChartPoint> monthly;

  AnalyticsData({
    required this.weekly,
    required this.monthly,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      weekly: (json['weekly'] as List<dynamic>?)
              ?.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthly: (json['monthly'] as List<dynamic>?)
              ?.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ChartPoint {
  final String date;
  final int steps;

  ChartPoint({
    required this.date,
    required this.steps,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      date: json['date'] as String? ?? '',
      steps: json['steps'] as int? ?? 0,
    );
  }
}
