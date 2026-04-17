import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../services/game_service.dart';
import 'subscription_provider.dart';

class CirclesState {
  final List<Map<String, dynamic>> circles;
  final List<Map<String, dynamic>> allCircles;
  final bool isLoading;
  final bool isCreating;
  final bool isJoining;
  final String? error;
  final String? infoMessage;

  const CirclesState({
    this.circles = const [],
    this.allCircles = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isJoining = false,
    this.error,
    this.infoMessage,
  });

  bool get isBusy => isLoading || isCreating || isJoining;

  CirclesState copyWith({
    List<Map<String, dynamic>>? circles,
    List<Map<String, dynamic>>? allCircles,
    bool? isLoading,
    bool? isCreating,
    bool? isJoining,
    String? error,
    String? infoMessage,
  }) {
    return CirclesState(
      circles: circles ?? this.circles,
      allCircles: allCircles ?? this.allCircles,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isJoining: isJoining ?? this.isJoining,
      error: error,
      infoMessage: infoMessage,
    );
  }
}

class CirclesNotifier extends StateNotifier<CirclesState> {
  final GameService _gameService;
  final Ref _ref;

  CirclesNotifier(this._gameService, this._ref) : super(const CirclesState()) {
    refreshCircles();
  }

  Future<void> refreshCircles({bool showLoader = true}) async {
    if (showLoader) {
      state = state.copyWith(isLoading: true, error: null, infoMessage: null);
    }

    try {
      final circles = await _gameService.getMyCircles();
      state = state.copyWith(
        circles: circles,
        isLoading: false,
        error: null,
        infoMessage: state.infoMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        infoMessage: null,
      );
    }
  }

  Future<Map<String, dynamic>> createCircle({
    required String name,
    bool isPrivate = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      const error = 'Circle name is required';
      state = state.copyWith(error: error, infoMessage: null);
      return {'success': false, 'error': error};
    }

    final subState = _ref.read(subscriptionProvider);
    if (state.circles.length >= subState.maxCircles) {
      final error =
          'Circle limit reached (${subState.maxCircles}). Upgrade to Premium for up to 5 circles.';
      state = state.copyWith(error: error, infoMessage: null);
      return {'success': false, 'error': error};
    }

    state = state.copyWith(
      isLoading: true,
      isCreating: true,
      error: null,
      infoMessage: null,
    );

    try {
      final response = await _gameService.createCircle(trimmedName);
      final success = response['success'] == true;

      if (!success) {
        final error =
            response['error']?.toString() ?? 'Failed to create circle';
        state = state.copyWith(
          isLoading: false,
          isCreating: false,
          error: error,
          infoMessage: null,
        );
        return {'success': false, 'error': error};
      }

      await refreshCircles(showLoader: false);

      final inviteCode = response['invite_code']?.toString();
      final visibility = isPrivate ? 'private' : 'public';
      final infoMessage = inviteCode == null
          ? 'Circle created ($visibility).'
          : 'Circle created ($visibility). Invite code: $inviteCode';

      state = state.copyWith(
        isLoading: false,
        isCreating: false,
        error: null,
        infoMessage: infoMessage,
      );

      return response;
    } catch (e) {
      final error = e.toString();
      state = state.copyWith(
        isLoading: false,
        isCreating: false,
        error: error,
        infoMessage: null,
      );
      return {'success': false, 'error': error};
    }
  }


Future<Map<String, dynamic>> getCircleById(String circleId) async {
    state = state.copyWith(isLoading: true, error: null, infoMessage: null);
    try {
      final circleDetails = await _gameService.getCircleDetails(circleId);
      state = state.copyWith(
        isLoading: false,
        error: null,
        infoMessage: null,
      );
      return {'success': true, 'circle': circleDetails};
    } catch (e) {
      final error = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: error,
        infoMessage: null,
      );
      return {'success': false, 'error': error};
    }
    
  }

  Future<Map<String, dynamic>> joinCircleByCode(String code) async {
    final inviteCode = code.trim().toUpperCase();
    if (inviteCode.isEmpty) {
      const error = 'Invite code is required';
      state = state.copyWith(error: error, infoMessage: null);
      return {'success': false, 'error': error};
    }

    state = state.copyWith(
      isLoading: true,
      isJoining: true,
      error: null,
      infoMessage: null,
    );

    try {
      final response = await _gameService.joinCircleByCode(inviteCode);
      final success = response['success'] == true;

      if (!success) {
        final error = response['error']?.toString() ?? 'Failed to join circle';
        state = state.copyWith(
          isLoading: false,
          isJoining: false,
          error: error,
          infoMessage: null,
        );
        return {'success': false, 'error': error};
      }

      await refreshCircles(showLoader: false);
      final joinedName = response['circle_name']?.toString() ?? 'circle';
      state = state.copyWith(
        isLoading: false,
        isJoining: false,
        error: null,
        infoMessage: 'Joined $joinedName successfully.',
      );
      return response;
    } catch (e) {
      final error = e.toString();
      state = state.copyWith(
        isLoading: false,
        isJoining: false,
        error: error,
        infoMessage: null,
      );
      return {'success': false, 'error': error};
    }
  }

  Future<void> leaveCircle(String circleId) async {
    state = state.copyWith(isLoading: true, error: null, infoMessage: null);
    try {
      final success = await _gameService.leaveCircle(circleId);
      if (success) {
        await refreshCircles(showLoader: false);
        state = state.copyWith(
          isLoading: false,
          error: null,
          infoMessage: 'Left circle successfully.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to leave circle',
          infoMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        infoMessage: null,
      );
    }
  }

  Future<void> refreshAllCircles({bool showLoader = true}) async {
    if (showLoader) {
      state = state.copyWith(isLoading: true, error: null, infoMessage: null);
    }

    try {
      final allCircles = await _gameService.getAllCircles();
      state = state.copyWith(
        allCircles: allCircles,
        isLoading: false,
        error: null,
        infoMessage: state.infoMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        infoMessage: null,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null, infoMessage: state.infoMessage);
  }

  void clearInfoMessage() {
    state = state.copyWith(error: state.error, infoMessage: null);
  }
}

final circlesProvider = StateNotifierProvider<CirclesNotifier, CirclesState>((
  ref,
) {
  return CirclesNotifier(GameService(), ref);
});

final activeSeasonProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return GameService().getActiveSeason();
});

final circleDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, circleId) async {
      return GameService().getCircleDetails(circleId);
    });

final circleLeaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      circleId,
    ) async {
      return GameService().getCircleLeaderboard(circleId);
    });
