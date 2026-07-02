import 'package:test_steps/models/badge_model.dart';

enum DashboardStatsRange { week, month, year, allTime }

class DashboardDistanceDay {
  const DashboardDistanceDay({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.durationSeconds,
  });

  final DateTime date;
  final int steps;
  final double distanceKm;
  final int durationSeconds;

  String get dayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

class DashboardDistancePoint {
  const DashboardDistancePoint({
    required this.label,
    required this.steps,
    required this.distanceKm,
    required this.durationSeconds,
  });

  final String label;
  final int steps;
  final double distanceKm;
  final int durationSeconds;
}

class DashboardTerritoryDay {
  const DashboardTerritoryDay({required this.date, required this.areaKm2});

  final DateTime date;
  final double areaKm2;

  String get dayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

class DashboardTerritoryPoint {
  const DashboardTerritoryPoint({required this.label, required this.areaKm2});

  final String label;
  final double areaKm2;
}

class TerritoryHistoryEntry {
  const TerritoryHistoryEntry({
    required this.id,
    required this.territoryId,
    required this.action,
    required this.energyUsed,
    required this.energyBefore,
    required this.energyAfter,
    required this.captured,
    required this.createdAt,
    required this.isDefence,
  });

  final String id;
  final String territoryId;
  final String action;
  final int energyUsed;
  final int? energyBefore;
  final int? energyAfter;
  final bool captured;
  final DateTime createdAt;
  final bool isDefence;

  factory TerritoryHistoryEntry.fromJson(Map<String, dynamic> json) {
    final captured = json['captured'] == true;
    final energyBefore = _historyNullableInt(json['energy_before']);
    final energyAfter = _historyNullableInt(json['energy_after']);
    final storedAction = json['action']?.toString().trim() ?? '';
    final inferredAction = captured
        ? 'captured'
        : (energyAfter ?? 0) > (energyBefore ?? 0)
        ? 'reinforced'
        : 'damaged';

    return TerritoryHistoryEntry(
      id: json['id']?.toString() ?? '',
      territoryId: json['territory_id']?.toString() ?? '',
      action: storedAction.isEmpty ? inferredAction : storedAction,
      energyUsed: _historyInt(json['energy_used']),
      energyBefore: energyBefore,
      energyAfter: energyAfter,
      captured: captured,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isDefence: json['is_defence'] == true,
    );
  }
}

int _historyInt(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _historyNullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

/// State exposed by the dashboard provider.
class DashboardState {
  final String username;
  final int steps;
  final Map<DateTime, int> weeklySteps;
  final List<DashboardDistanceDay> distanceGraphDays;
  final bool isGraphLoading;
  final String? graphError;
  final List<DashboardTerritoryDay> territoryGraphDays;
  final bool isTerritoryGraphLoading;
  final String? territoryGraphError;
  final int weeklyStreak;
  final int monthlyStreak;
  final int attackEnergy;
  final int attackEnergyCap;
  final int level;
  final int xp;
  final int xpGoal;
  final int stepGoal;
  final int calories;
  final int durationSeconds;
  final int? heartRate;
  final double distanceKm;
  final double totalAreaKm2;
  final List<BadgeModel> badges;
  final List<TerritoryHistoryEntry> territoryHistory;
  final bool isLoading;
  final bool permissionsGranted;
  final String? error;

  const DashboardState({
    required this.username,
    required this.steps,
    required this.weeklySteps,
    required this.distanceGraphDays,
    required this.isGraphLoading,
    this.graphError,
    required this.territoryGraphDays,
    required this.isTerritoryGraphLoading,
    this.territoryGraphError,
    required this.weeklyStreak,
    required this.monthlyStreak,
    required this.attackEnergy,
    required this.attackEnergyCap,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.stepGoal,
    required this.calories,
    required this.durationSeconds,
    required this.heartRate,
    required this.distanceKm,
    required this.totalAreaKm2,
    required this.badges,
    required this.territoryHistory,
    required this.isLoading,
    required this.permissionsGranted,
    this.error,
  });

  factory DashboardState.initial() => const DashboardState(
    username: 'User',
    steps: 0,
    weeklySteps: {},
    distanceGraphDays: [],
    isGraphLoading: false,
    territoryGraphDays: [],
    isTerritoryGraphLoading: false,
    weeklyStreak: 0,
    monthlyStreak: 0,
    attackEnergy: 0,
    attackEnergyCap: 400,
    level: 1,
    xp: 0,
    xpGoal: 1000,
    stepGoal: 10000,
    calories: 0,
    durationSeconds: 0,
    heartRate: null,
    distanceKm: 0.0,
    totalAreaKm2: 0.0,
    badges: [],
    territoryHistory: [],
    isLoading: true,
    permissionsGranted: false,
  );

  DashboardState copyWith({
    String? username,
    int? steps,
    Map<DateTime, int>? weeklySteps,
    List<DashboardDistanceDay>? distanceGraphDays,
    bool? isGraphLoading,
    String? graphError,
    List<DashboardTerritoryDay>? territoryGraphDays,
    bool? isTerritoryGraphLoading,
    String? territoryGraphError,
    int? weeklyStreak,
    int? monthlyStreak,
    int? attackEnergy,
    int? attackEnergyCap,
    int? level,
    int? xp,
    int? xpGoal,
    int? stepGoal,
    int? calories,
    int? durationSeconds,
    int? heartRate,
    double? distanceKm,
    double? totalAreaKm2,
    List<BadgeModel>? badges,
    List<TerritoryHistoryEntry>? territoryHistory,
    bool? isLoading,
    bool? permissionsGranted,
    String? error,
  }) => DashboardState(
    username: username ?? this.username,
    steps: steps ?? this.steps,
    weeklySteps: weeklySteps ?? this.weeklySteps,
    distanceGraphDays: distanceGraphDays ?? this.distanceGraphDays,
    isGraphLoading: isGraphLoading ?? this.isGraphLoading,
    graphError: graphError,
    territoryGraphDays: territoryGraphDays ?? this.territoryGraphDays,
    isTerritoryGraphLoading:
        isTerritoryGraphLoading ?? this.isTerritoryGraphLoading,
    territoryGraphError: territoryGraphError,
    weeklyStreak: weeklyStreak ?? this.weeklyStreak,
    monthlyStreak: monthlyStreak ?? this.monthlyStreak,
    attackEnergy: attackEnergy ?? this.attackEnergy,
    attackEnergyCap: attackEnergyCap ?? this.attackEnergyCap,
    level: level ?? this.level,
    xp: xp ?? this.xp,
    xpGoal: xpGoal ?? this.xpGoal,
    stepGoal: stepGoal ?? this.stepGoal,
    calories: calories ?? this.calories,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    heartRate: heartRate ?? this.heartRate,
    distanceKm: distanceKm ?? this.distanceKm,
    totalAreaKm2: totalAreaKm2 ?? this.totalAreaKm2,
    badges: badges ?? this.badges,
    territoryHistory: territoryHistory ?? this.territoryHistory,
    isLoading: isLoading ?? this.isLoading,
    permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    error: error,
  );
}
