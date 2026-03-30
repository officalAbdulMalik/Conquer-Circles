import 'dart:async';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/models/messages_models.dart';
import '../services/game_service.dart';

class CircleMessagesNotifier extends StateNotifier<CircleMessagesState> {
  final GameService _gameService;
  final String _circleId;
  RealtimeChannel? _channel;
  final SupabaseClient _client = Supabase.instance.client;
  CircleMessagesNotifier(this._gameService, this._circleId)
    : super(CircleMessagesState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _fetchInitialMessages();
    _subscribe();
  }

  Future<void> _fetchInitialMessages() async {
    try {
      final rows = await _client
          .from('circle_messages')
          .select('*, profiles(username)')
          .eq('circle_id', _circleId)
          .order('created_at', ascending: false)
          .limit(50);

      final messages = List<Map<String, dynamic>>.from(rows as List);

      state = state.copyWith(messages: [...messages], isLoading: false);
    } catch (e) {
      print('Error fetching initial messages: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void _subscribe() {
    _channel?.unsubscribe();

    _channel = _client.channel('public:circle_messages:$_circleId');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'circle_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'circle_id',
            value: _circleId,
          ),
          callback: (payload) async {
            print('New real-time message received: ${payload.newRecord}');
            final newMsg = Map<String, dynamic>.from(payload.newRecord);
            if (newMsg['user_id'] == _client.auth.currentUser?.id) return;
            final currentMessages = state.messages;
            print("Message here ${currentMessages} ");

            List<Map<String, dynamic>> messages = state.messages;
            messages.insert(0, newMsg);
            messages.sort(
              (a, b) => DateTime.parse(
                b['created_at'],
              ).compareTo(DateTime.parse(a['created_at'])),
            );
            state = state.copyWith(messages: [...messages]);
          },
        )
        .subscribe((status, [error]) {
          print('Subscription status for $_circleId: $status');
          if (error != null) print('Subscription error: $error');
        });
  }

  Future<void> sendMessage(String content) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final optimisticMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'circle_id': _circleId,
      'user_id': user.id,
      'message': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_optimistic': true,
    };

    List<Map<String, dynamic>> messages = state.messages;
    messages.insert(0, optimisticMsg);
    messages.sort(
      (a, b) => DateTime.parse(
        b['created_at'],
      ).compareTo(DateTime.parse(a['created_at'])),
    );
    state = state.copyWith(messages: [...messages]);

    try {
      await _gameService.sendCircleMessage(_circleId, content);
    } catch (e) {
      // _optimisticMessages.remove(optimisticMsg);
      // state = state.copyWith(
      //   messages: state.messages
      //       .where((m) => m['id'] != optimisticMsg['id'])
      //       .toList(),
      //   error: "Failed to send message: $e",
      // );
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final circleMessagesProvider =
    StateNotifierProvider.family<
      CircleMessagesNotifier,
      CircleMessagesState,
      String
    >((ref, circleId) {
      return CircleMessagesNotifier(GameService(), circleId);
    });
