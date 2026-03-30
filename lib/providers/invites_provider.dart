import 'dart:async';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invite_model.dart';
 import '../services/supabase_service.dart';
import '../services/notification_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class InvitesState {
  final List<Invite> receivedInvites;
  final List<Invite> sentInvites;
  final List<UserProfile> searchResults;
  final bool isLoading;
  final String? error;

  const InvitesState({
    this.receivedInvites = const [],
    this.sentInvites = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
  });

  /// Pending (unactioned) received invites — drives the nav badge count.
  int get pendingCount => receivedInvites.where((i) => i.isPending).length;

  InvitesState copyWith({
    List<Invite>? receivedInvites,
    List<Invite>? sentInvites,
    List<UserProfile>? searchResults,
    bool? isLoading,
    String? error,
  }) => InvitesState(
    receivedInvites: receivedInvites ?? this.receivedInvites,
    sentInvites: sentInvites ?? this.sentInvites,
    searchResults: searchResults ?? this.searchResults,
    isLoading: isLoading ?? this.isLoading,
    error: error, // always replace — null clears the error
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class InvitesNotifier extends StateNotifier<InvitesState> {
  final SupabaseService _service;
  Timer? _refreshTimer;
  RealtimeChannel? _channel;

  InvitesNotifier(this._service) : super(const InvitesState()) {
    fetchInvites();
    _subscribeToRealtime();
    // Fallback polling every 30 s in case realtime misses an event
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchInvites(),
    );
  }

  // ── Realtime subscription ──────────────────────────────────────────────────

  void _subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = Supabase.instance.client
        .channel('invites_realtime_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'invitee_id',
            value: userId,
          ),
          callback: (_) => fetchInvites(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'inviter_id',
            value: userId,
          ),
          callback: (_) => fetchInvites(),
        )
        .subscribe();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchInvites() async {
    try {
      final received = await _service.getReceivedInvites();
      final sent = await _service.getSentInvites();
      state = state.copyWith(
        receivedInvites: received,
        sentInvites: sent,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  /// Searches ALL users (for the invite discovery screen).
  /// Uses searchAllUsers so already-invited users are still visible.
  Future<void> searchAllUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], error: null);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchAllUsers(query);
      state = state.copyWith(searchResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Searches only users who have NOT already been invited (for the send screen).
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], error: null);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchUsers(query);
      state = state.copyWith(searchResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> sendInvite(String inviteeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.sendInvite(inviteeId);
      final profile = await _service.getProfile();
      final inviterName = profile?['username'] as String? ?? 'Someone';
      await NotificationService.notifyCircleInvite(inviteeId, inviterName);
      await fetchInvites();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateInviteStatus(inviteId, 'accepted');
      // Potential: Notify inviter that friend joined
      // But usually handled by friend_joined_circle trigger in CircleProvider
      await fetchInvites();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> rejectInvite(String inviteId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateInviteStatus(inviteId, 'rejected');
      await fetchInvites();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final invitesProvider = StateNotifierProvider<InvitesNotifier, InvitesState>((
  ref,
) {
  return InvitesNotifier(SupabaseService());
});
