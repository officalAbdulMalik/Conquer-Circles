import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/features/social/models/circle_models.dart';

import '../services/game_service.dart';
// import 'subscription_provider.dart';

class CirclesState {
  final List<CircleModel> circles;
  final List<CircleModel> allCircles;
  final List<CircleJoinRequestModel> incomingJoinRequests;
  final Map<String, String> joinRequestStatuses;
  final bool isLoading;
  final bool isCreating;
  final bool isJoining;
  final Set<String> requestingCircleIds;
  final Set<String> respondingRequestIds;
  final Set<String> removingMemberIds;
  final String? error;
  final String? infoMessage;

  const CirclesState({
    this.circles = const [],
    this.allCircles = const [],
    this.incomingJoinRequests = const [],
    this.joinRequestStatuses = const {},
    this.isLoading = false,
    this.isCreating = false,
    this.isJoining = false,
    this.requestingCircleIds = const {},
    this.respondingRequestIds = const {},
    this.removingMemberIds = const {},
    this.error,
    this.infoMessage,
  });

  bool get isBusy => isLoading || isCreating || isJoining;

  CirclesState copyWith({
    List<CircleModel>? circles,
    List<CircleModel>? allCircles,
    List<CircleJoinRequestModel>? incomingJoinRequests,
    Map<String, String>? joinRequestStatuses,
    bool? isLoading,
    bool? isCreating,
    bool? isJoining,
    Set<String>? requestingCircleIds,
    Set<String>? respondingRequestIds,
    Set<String>? removingMemberIds,
    String? error,
    String? infoMessage,
  }) {
    return CirclesState(
      circles: circles ?? this.circles,
      allCircles: allCircles ?? this.allCircles,
      incomingJoinRequests: incomingJoinRequests ?? this.incomingJoinRequests,
      joinRequestStatuses: joinRequestStatuses ?? this.joinRequestStatuses,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isJoining: isJoining ?? this.isJoining,
      requestingCircleIds: requestingCircleIds ?? this.requestingCircleIds,
      respondingRequestIds: respondingRequestIds ?? this.respondingRequestIds,
      removingMemberIds: removingMemberIds ?? this.removingMemberIds,
      error: error,
      infoMessage: infoMessage,
    );
  }
}

class CirclesNotifier extends StateNotifier<CirclesState> {
  final GameService _gameService;
  RealtimeChannel? _joinRequestsChannel;
  Timer? _joinRequestsRefreshTimer;

  String? _selectedIcon;

  String? get selectedCircleImage => _selectedIcon;

  set selectCircleImage(String? value) {
    _selectedIcon = value;
  }

  List<String> circleImages = [
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/1.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/10.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/11.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/12.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/2.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/3.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/4.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/5.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/6.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/7.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/8.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/9.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/13.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/14.png',
    'https://dpvelnjzovjhxgpjvtay.supabase.co/storage/v1/object/public/assets/15.png',
  ];

  CirclesNotifier(this._gameService, Ref _) : super(const CirclesState()) {
    refreshCircles();
    refreshJoinRequests();
    _subscribeToJoinRequests();
    _joinRequestsRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshJoinRequests(),
    );
  }

  void _subscribeToJoinRequests() {
    final userId = _gameService.currentUser?.id;
    if (userId == null) return;
    _joinRequestsChannel = Supabase.instance.client
        .channel('circle_join_requests_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'circle_join_requests',
          callback: (_) async {
            await refreshJoinRequests();
            await refreshAllCircles(showLoader: false);
          },
        )
        .subscribe();
  }

  Future<void> refreshCircles({bool showLoader = true}) async {
    if (showLoader) {
      state = state.copyWith(isLoading: true, error: null, infoMessage: null);
    }

    try {
      final rows = await _gameService.getMyCircles();
      final circles = rows.map(CircleModel.fromJson).toList();
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
    String? iconUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      const error = 'Circle name is required';
      state = state.copyWith(error: error, infoMessage: null);
      return {'success': false, 'error': error};
    }

    // Temporarily disabled for testing unlimited circle creation.
    // final subState = _ref.read(subscriptionProvider);
    // if (state.circles.length >= subState.maxCircles) {
    //   final error =
    //       'Circle limit reached (${subState.maxCircles}). Upgrade to Premium for up to 5 circles.';
    //   state = state.copyWith(error: error, infoMessage: null);
    //   return {'success': false, 'error': error};
    // }

    state = state.copyWith(
      isLoading: true,
      isCreating: true,
      error: null,
      infoMessage: null,
    );

    try {
      final response = await _gameService.createCircle(
        trimmedName,
        isPrivate: isPrivate,
        iconUrl: iconUrl,
      );
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
      state = state.copyWith(isLoading: false, error: null, infoMessage: null);
      return {'success': true, 'circle': circleDetails};
    } catch (e) {
      final error = e.toString();
      state = state.copyWith(isLoading: false, error: error, infoMessage: null);
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
      final rows = await _gameService.getAllCircles();
      final statuses = await _gameService.getMyCircleJoinRequestStatuses();
      final circlesWithRequests = rows
          .map(CircleModel.fromJson)
          .map(
            (circle) => circle.copyWith(joinRequestStatus: statuses[circle.id]),
          )
          .toList();
      state = state.copyWith(
        allCircles: circlesWithRequests,
        joinRequestStatuses: statuses,
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

  Future<void> refreshJoinRequests() async {
    try {
      final rows = await _gameService.getIncomingCircleJoinRequests();
      final incoming = rows.map(CircleJoinRequestModel.fromJson).toList();
      final statuses = await _gameService.getMyCircleJoinRequestStatuses();
      state = state.copyWith(
        incomingJoinRequests: incoming,
        joinRequestStatuses: statuses,
        error: state.error,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Map<String, dynamic>> requestToJoinCircle(String circleId) async {
    if (!_isUuid(circleId)) {
      return {'success': false, 'error': 'Circle is unavailable'};
    }
    if (state.requestingCircleIds.contains(circleId)) {
      return {'success': false, 'error': 'Join request is already sending'};
    }

    final requestingCircleIds = Set<String>.from(state.requestingCircleIds)
      ..add(circleId);
    state = state.copyWith(
      isJoining: true,
      requestingCircleIds: requestingCircleIds,
      error: null,
      infoMessage: null,
    );

    final response = await _gameService.requestToJoinCircle(circleId);
    final updatedRequestingIds = Set<String>.from(state.requestingCircleIds)
      ..remove(circleId);

    if (response['success'] != true) {
      final error =
          response['error']?.toString() ?? 'Could not send join request';
      state = state.copyWith(
        isJoining: updatedRequestingIds.isNotEmpty,
        requestingCircleIds: updatedRequestingIds,
        error: error,
        infoMessage: null,
      );
      return {'success': false, 'error': error};
    }

    final requestStatus = response['status']?.toString() ?? 'pending';
    final statuses = Map<String, String>.from(state.joinRequestStatuses)
      ..[circleId] = requestStatus;
    final allCircles = state.allCircles.map((circle) {
      if (circle.id != circleId) return circle;
      return circle.copyWith(joinRequestStatus: requestStatus);
    }).toList();
    state = state.copyWith(
      allCircles: allCircles,
      joinRequestStatuses: statuses,
      isJoining: updatedRequestingIds.isNotEmpty,
      requestingCircleIds: updatedRequestingIds,
      error: null,
      infoMessage: 'Join request sent.',
    );
    return response;
  }

  Future<Map<String, dynamic>> respondToJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    final responding = Set<String>.from(state.respondingRequestIds)
      ..add(requestId);
    state = state.copyWith(respondingRequestIds: responding, error: null);

    final response = await _gameService.respondToCircleJoinRequest(
      requestId: requestId,
      accept: accept,
    );
    final updatedResponding = Set<String>.from(state.respondingRequestIds)
      ..remove(requestId);

    if (response['success'] != true) {
      final error =
          response['error']?.toString() ?? 'Could not update join request';
      state = state.copyWith(
        respondingRequestIds: updatedResponding,
        error: error,
      );
      return {'success': false, 'error': error};
    }

    state = state.copyWith(
      incomingJoinRequests: state.incomingJoinRequests
          .where((request) => request.id != requestId)
          .toList(),
      respondingRequestIds: updatedResponding,
      error: null,
      infoMessage: accept ? 'Member added to circle.' : 'Request rejected.',
    );
    if (accept) {
      await refreshCircles(showLoader: false);
      await refreshAllCircles(showLoader: false);
    }
    return response;
  }

  Future<Map<String, dynamic>> removeCircleMember({
    required String circleId,
    required String memberId,
  }) async {
    if (state.removingMemberIds.contains(memberId)) {
      return {'success': false, 'error': 'Member removal is already running'};
    }

    final removingIds = Set<String>.from(state.removingMemberIds)
      ..add(memberId);
    state = state.copyWith(removingMemberIds: removingIds, error: null);

    final response = await _gameService.removeCircleMember(
      circleId: circleId,
      memberId: memberId,
    );
    final updatedRemovingIds = Set<String>.from(state.removingMemberIds)
      ..remove(memberId);

    if (response['success'] != true) {
      final error =
          response['error']?.toString() ?? 'Could not remove circle member';
      state = state.copyWith(
        removingMemberIds: updatedRemovingIds,
        error: error,
      );
      return {'success': false, 'error': error};
    }

    await refreshCircles(showLoader: false);
    await refreshAllCircles(showLoader: false);
    state = state.copyWith(
      removingMemberIds: updatedRemovingIds,
      error: null,
      infoMessage: 'Member removed from circle.',
    );
    return response;
  }

  void clearError() {
    state = state.copyWith(error: null, infoMessage: state.infoMessage);
  }

  void clearInfoMessage() {
    state = state.copyWith(error: state.error, infoMessage: null);
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  @override
  void dispose() {
    _joinRequestsRefreshTimer?.cancel();
    _joinRequestsChannel?.unsubscribe();
    super.dispose();
  }
}

final circlesProvider = StateNotifierProvider<CirclesNotifier, CirclesState>((
  ref,
) {
  return CirclesNotifier(GameService(), ref);
});

final currentCircleUserIdProvider = Provider<String?>((ref) {
  return GameService().currentUser?.id;
});

final activeSeasonProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return GameService().getActiveSeason();
});

final circleDetailsProvider =
    FutureProvider.family<CircleDetailsModel?, String>((ref, circleId) async {
      final response = await GameService().getCircleDetails(circleId);
      return response == null ? null : CircleDetailsModel.fromJson(response);
    });

final circleLeaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      circleId,
    ) async {
      return GameService().getCircleLeaderboard(circleId);
    });
