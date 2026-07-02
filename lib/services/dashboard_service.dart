import 'dart:async';
import 'dart:developer' as developer;
import 'package:riverpod/legacy.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/models/badge_model.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(SupabaseService());
    });

class DashboardNotifier extends StateNotifier<DashboardState> {
  final SupabaseService _supabaseService;
  int _graphRequestSequence = 0;
  int _territoryGraphRequestSequence = 0;
  Future<void>? _dashboardLoad;
  bool _hasLoadedDashboard = false;
  String? _loadedGraphRequestKey;
  String? _loadingGraphRequestKey;
  String? _loadedTerritoryGraphRequestKey;
  String? _loadingTerritoryGraphRequestKey;

  DashboardNotifier(this._supabaseService) : super(DashboardState.initial());

  /// Loads the dashboard summary data from Supabase.
  Future<void> loadDashboard({bool force = false}) {
    if (!force && _hasLoadedDashboard) {
      return Future<void>.value();
    }

    final activeLoad = _dashboardLoad;
    if (activeLoad != null) return activeLoad;

    final load = _loadDashboard();
    _dashboardLoad = load;
    return load.whenComplete(() {
      _dashboardLoad = null;
    });
  }

  Future<void> _loadDashboard() async {
    developer.log('loadDashboard');
    developer.log(
      'Current user ID: ${_supabaseService.currentUser?.id ?? 'not signed in'}',
      name: 'DashboardNotifier',
    );

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        permissionsGranted: true,
      );

      final dashboardData = await _supabaseService.getStepsDashboardData();
      developer.log('Fetched dashboard data from Supabase: $dashboardData');

      final profile = dashboardData['profile'] as Map<String, dynamic>? ?? {};
      final today = dashboardData['today'] as Map<String, dynamic>? ?? {};
      final weeklyRaw = dashboardData['weekly_steps'] as List? ?? [];
      final badgesRaw = dashboardData['badges'] as List? ?? [];

      final Map<DateTime, int> weeklySteps = {};
      for (final row in weeklyRaw) {
        final date = DateTime.parse(row['date'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        weeklySteps[normalizedDate] = _readInt(row['steps']);
      }

      final badges = badgesRaw
          .map((b) => BadgeModel.fromJson(b as Map<String, dynamic>))
          .toList();
      List<TerritoryHistoryEntry> territoryHistory;
      try {
        territoryHistory = await _supabaseService.getTerritoryHistory();
      } catch (e) {
        developer.log('Direct territory history load failed: $e');
        final territoryHistoryRaw =
            dashboardData['territory_history'] as List? ?? [];
        territoryHistory = territoryHistoryRaw
            .map(
              (entry) => TerritoryHistoryEntry.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
      }

      state = state.copyWith(
        username: _readString(profile['username'], fallback: 'User'),
        steps: _readInt(today['steps']),
        calories: _readInt(today['calories']),
        durationSeconds: _readInt(today['duration_seconds']),
        heartRate: today['heart_rate'] == null
            ? null
            : _readInt(today['heart_rate']),
        distanceKm: _readDouble(today['distance_km']),
        totalAreaKm2: _readDouble(today['total_area_km2']),
        level: _readInt(profile['level'], fallback: 1),
        xp: _readInt(profile['xp']),
        xpGoal: _readInt(profile['xp_goal'], fallback: 1000),
        stepGoal: _readInt(profile['step_goal'], fallback: 10000),
        weeklyStreak: _readInt(profile['streak']),
        attackEnergy: _readInt(profile['attack_energy']),
        attackEnergyCap: _readInt(profile['attack_energy_cap'], fallback: 400),
        weeklySteps: weeklySteps,
        badges: badges,
        territoryHistory: territoryHistory,
        isLoading: false,
        permissionsGranted: true,
      );
      _hasLoadedDashboard = true;
    } catch (e) {
      developer.log('Failed to load dashboard data: $e');
      final errorMessage = e.toString();

      if (errorMessage.contains('Session mismatch') ||
          errorMessage.contains('No active session')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Session expired. Please log in again.',
          permissionsGranted: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load dashboard data',
          permissionsGranted: true,
        );
      }
    }
  }

  Future<void> refresh() => loadDashboard(force: true);

  void applyTerritoryActionResult(Map<String, dynamic> result) {
    final action = result['action']?.toString();
    final territoryId = result['territory_id']?.toString();
    if (action == null ||
        territoryId == null ||
        territoryId.isEmpty ||
        !_isHistoryAction(action)) {
      return;
    }

    final entry = TerritoryHistoryEntry.fromJson({
      'id':
          result['attack_log_id']?.toString() ??
          'pending_${territoryId}_${DateTime.now().microsecondsSinceEpoch}',
      'territory_id': territoryId,
      'action': action,
      'energy_used':
          result['energy_used'] ??
          result['attack_energy_used'] ??
          result['energy_to_consume'] ??
          0,
      'energy_before':
          result['territory_energy_before'] ?? result['energy_before'],
      'energy_after':
          result['territory_energy_after'] ?? result['energy_after'],
      'captured': action == 'captured',
      'created_at':
          result['created_at']?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
      'is_defence': false,
    });

    final existing = state.territoryHistory.where(
      (item) => item.id != entry.id,
    );
    state = state.copyWith(territoryHistory: [entry, ...existing]);
  }

  Future<void> refreshAfterMapActivity({
    Map<String, dynamic>? optimisticResult,
  }) async {
    if (optimisticResult != null) {
      applyTerritoryActionResult(optimisticResult);
    }
    await loadDashboard(force: true);
  }

  Future<void> refreshTerritoryHistory() async {
    try {
      final history = await _supabaseService.getTerritoryHistory();
      state = state.copyWith(territoryHistory: history);
    } catch (e) {
      developer.log('Failed to refresh territory history: $e');
    }
  }

  bool _isHistoryAction(String action) {
    return action == 'claimed' ||
        action == 'captured' ||
        action == 'damaged' ||
        action == 'reinforced';
  }

  void updateAttackEnergy(int energy) {
    state = state.copyWith(attackEnergy: energy);
  }

  Future<void> reloadAttackEnergy() async {
    try {
      final energy = await _supabaseService.getAttackEnergy();
      updateAttackEnergy(energy);
    } catch (e) {
      developer.log('Failed to reload dashboard attack energy: $e');
    }
  }

  Future<void> loadDistanceGraph({
    DateTime? from,
    required DateTime to,
    bool allTime = false,
    bool force = false,
  }) async {
    final requestKey = allTime
        ? 'all-time'
        : '${_dateKey(from!)}:${_dateKey(to)}';
    if (!force &&
        (_loadedGraphRequestKey == requestKey ||
            _loadingGraphRequestKey == requestKey)) {
      return;
    }

    final requestSequence = ++_graphRequestSequence;
    _loadingGraphRequestKey = requestKey;
    state = state.copyWith(isGraphLoading: true, graphError: null);

    try {
      final days = allTime
          ? await _supabaseService.getAllTimeDistanceGraphData()
          : await _supabaseService.getDistanceGraphData(from: from!, to: to);
      if (requestSequence != _graphRequestSequence) return;
      _loadedGraphRequestKey = requestKey;
      state = state.copyWith(
        distanceGraphDays: days,
        isGraphLoading: false,
        graphError: null,
      );
    } catch (e) {
      if (requestSequence != _graphRequestSequence) return;
      developer.log('Failed to load distance graph data: $e');
      state = state.copyWith(
        distanceGraphDays: const [],
        isGraphLoading: false,
        graphError: 'Could not load distance graph',
      );
    } finally {
      if (_loadingGraphRequestKey == requestKey) {
        _loadingGraphRequestKey = null;
      }
    }
  }

  Future<void> loadTerritoryGraph({
    DateTime? from,
    required DateTime to,
    bool allTime = false,
    bool force = false,
  }) async {
    final requestKey = allTime
        ? 'all-time'
        : '${_dateKey(from!)}:${_dateKey(to)}';
    if (!force &&
        (_loadedTerritoryGraphRequestKey == requestKey ||
            _loadingTerritoryGraphRequestKey == requestKey)) {
      return;
    }

    final requestSequence = ++_territoryGraphRequestSequence;
    _loadingTerritoryGraphRequestKey = requestKey;
    state = state.copyWith(
      isTerritoryGraphLoading: true,
      territoryGraphError: null,
    );

    try {
      final days = allTime
          ? await _supabaseService.getAllTimeTerritoryGraphData()
          : await _supabaseService.getTerritoryGraphData(from: from!, to: to);
      if (requestSequence != _territoryGraphRequestSequence) return;
      _loadedTerritoryGraphRequestKey = requestKey;
      state = state.copyWith(
        territoryGraphDays: days,
        isTerritoryGraphLoading: false,
        territoryGraphError: null,
      );
    } catch (e) {
      if (requestSequence != _territoryGraphRequestSequence) return;
      developer.log('Failed to load territory graph data: $e');
      state = state.copyWith(
        territoryGraphDays: const [],
        isTerritoryGraphLoading: false,
        territoryGraphError: 'Could not load territory graph',
      );
    } finally {
      if (_loadingTerritoryGraphRequestKey == requestKey) {
        _loadingTerritoryGraphRequestKey = null;
      }
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _readDouble(Object? value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _readString(Object? value, {required String fallback}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
