import 'package:riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_service.dart';
import 'subscription_provider.dart';

class CirclesState {
  final List<Map<String, dynamic>> circles;
  final bool isLoading;
  final String? error;

  CirclesState({
    this.circles = const [],
    this.isLoading = false,
    this.error,
  });

  CirclesState copyWith({
    List<Map<String, dynamic>>? circles,
    bool? isLoading,
    String? error,
  }) {
    return CirclesState(
      circles: circles ?? this.circles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CirclesNotifier extends StateNotifier<CirclesState> {
  final GameService gameService;

  CirclesNotifier(this.gameService) : super(CirclesState()) {
    refreshCircles();
  }

  Future<void> refreshCircles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final circles = await gameService.getMyCircles();
      state = state.copyWith(circles: circles, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<Map<String, dynamic>> createCircle(String name, WidgetRef ref) async {
    final subState = ref.read(subscriptionProvider);
    if (state.circles.length >= subState.maxCircles) {
      final error = 'Circle limit reached (${subState.maxCircles}). Upgrade to Premium for up to 5 circles.';
      state = state.copyWith(error: error, isLoading: false);
      return {'success': false, 'error': error};
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await gameService.createCircle(name);
      if (res['success'] == true) {
        await refreshCircles();
      } else {
        state = state.copyWith(error: res['error'], isLoading: false);
      }
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> joinCircleByCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await gameService.joinCircleByCode(code);
      if (res['success'] == true) {
        await refreshCircles();
      } else {
        state = state.copyWith(error: res['error'], isLoading: false);
      }
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> leaveCircle(String circleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await gameService.leaveCircle(circleId);
      if (success) {
        await refreshCircles();
      } else {
        state = state.copyWith(error: 'Failed to leave circle', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final circlesProvider = StateNotifierProvider<CirclesNotifier, CirclesState>((ref) {
  return CirclesNotifier(GameService());
});

final activeSeasonProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return GameService().getActiveSeason();
});

final circleLeaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, circleId) async {
  return GameService().getCircleLeaderboard(circleId);
});
