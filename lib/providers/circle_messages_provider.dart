import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:test_steps/models/messages_models.dart';

import '../services/game_service.dart';

class CircleMessagesNotifier extends StateNotifier<CircleMessagesState> {
  final GameService _gameService;
  final String _circleId;
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _channel;

  CircleMessagesNotifier(this._gameService, this._circleId)
    : super(CircleMessagesState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await refreshMessages();
    _subscribe();
  }

  Future<void> refreshMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rows = await _gameService.getCircleMessages(_circleId);
      final normalized = rows.map(_normalizeMessage).toList();
      state = state.copyWith(messages: _sortMessages(normalized), isLoading: false);
    } catch (e) {
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
          callback: (payload) {
            final newMessage = Map<String, dynamic>.from(payload.newRecord);
            _mergeIncomingMessage(_normalizeMessage(newMessage));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'circle_message_reactions',
          callback: (payload) {
            _handleReactionEvent(payload); 
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'circle_message_reactions',
          callback: (payload) {
            _handleReactionEvent(payload);
          },
        )
        .subscribe();
  }

  void _mergeIncomingMessage(Map<String, dynamic> incoming) {
    final incomingId = incoming['id']?.toString();
    final incomingUserId = incoming['user_id']?.toString();
    final incomingText = incoming['message']?.toString();

    final updated = state.messages.where((existing) {
      final existingId = existing['id']?.toString();
      if ((existingId ?? '').isNotEmpty && existingId == incomingId) {
        return false;
      }

      final bool isOptimistic = existing['is_optimistic'] == true;
      if (isOptimistic &&
          existing['user_id']?.toString() == incomingUserId &&
          existing['message']?.toString() == incomingText) {
        return false;
      }

      return true;
    }).toList();

    updated.add(incoming);
    state = state.copyWith(messages: _sortMessages(updated), error: null);
  }

  void _handleReactionEvent(dynamic payload) {
    final messageId = payload?.newRecord?['message_id']?.toString() ??
        payload?.oldRecord?['message_id']?.toString();
    if (messageId == null) return;
    if (!state.messages.any((message) => message['id']?.toString() == messageId)) {
      return;
    }
    refreshMessages();
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final messageIndex = state.messages.indexWhere(
      (message) => message['id']?.toString() == messageId,
    );
    if (messageIndex < 0) return;

    final currentMessages = List<Map<String, dynamic>>.from(state.messages);
    final currentMessage = Map<String, dynamic>.from(currentMessages[messageIndex]);
    final rawReactions = List<Map<String, dynamic>>.from(
      currentMessage['reactions'] ?? [],
    );
    final existing = rawReactions.firstWhere(
      (reaction) => reaction['emoji'] == emoji,
      orElse: () => {},
    );
    final isCurrentlySelected = existing.isNotEmpty && existing['selected'] == true;

    final optimisticReactions = rawReactions.map((reaction) {
      if (reaction['emoji'] == emoji) {
        final count = reaction['count'] is int ? reaction['count'] as int : int.tryParse('${reaction['count']}') ?? 0;
        return {
          'emoji': emoji,
          'count': isCurrentlySelected ? count - 1 : count + 1,
          'selected': !isCurrentlySelected,
        };
      }
      return reaction;
    }).where((reaction) => reaction['count'] != 0).toList();

    if (!isCurrentlySelected && existing.isEmpty) {
      optimisticReactions.add({'emoji': emoji, 'count': 1, 'selected': true});
    }

    currentMessage['reactions'] = optimisticReactions;
    currentMessages[messageIndex] = currentMessage;
    state = state.copyWith(messages: _sortMessages(currentMessages), error: null);

    final response = await _gameService.toggleCircleMessageReaction(messageId, emoji);
    if (response['success'] != true) {
      state = state.copyWith(error: response['error']?.toString() ?? 'Failed to update reaction');
      await refreshMessages();
      return;
    }

    final reactionPayload = response['reactions'];
    if (reactionPayload is List) {
      final updatedReactions = reactionPayload
          .map<Map<String, dynamic>>((raw) => {
                'emoji': raw['emoji']?.toString() ?? '',
                'count': raw['count'] is int ? raw['count'] as int : int.tryParse('${raw['count']}') ?? 0,
                'selected': raw['selected'] == true,
              })
          .where((reaction) => reaction['emoji']?.toString().isNotEmpty == true)
          .toList();

      currentMessage['reactions'] = updatedReactions;
      currentMessages[messageIndex] = currentMessage;
      state = state.copyWith(messages: _sortMessages(currentMessages), error: null);
    } else {
      await refreshMessages();
    }
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> row) {
    final currentUserId = _client.auth.currentUser?.id;
    final rawReactions = <Map<String, dynamic>>[];
    if (row['circle_message_reactions'] != null) {
      final list = row['circle_message_reactions'] as List;
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          rawReactions.add(raw);
        } else if (raw is Map) {
          rawReactions.add(Map<String, dynamic>.from(raw));
        }
      }
    }

    final aggregated = <String, Map<String, dynamic>>{};
    for (final reaction in rawReactions) {
      final emoji = reaction['emoji']?.toString();
      if (emoji == null || emoji.isEmpty) continue;
      final userId = reaction['user_id']?.toString();
      final existing = aggregated.putIfAbsent(emoji, () => {
            'emoji': emoji,
            'count': 0,
            'selected': false,
          });
      existing['count'] = (existing['count'] as int) + 1;
      if (userId != null && userId == currentUserId) {
        existing['selected'] = true;
      }
    }

    final normalized = Map<String, dynamic>.from(row);
    normalized['reactions'] = aggregated.values.toList();
    normalized.remove('circle_message_reactions');
    return normalized;
  }

  Future<void> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final user = _client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'Not signed in');
      return;
    }

    final optimisticMessage = {
      'id': 'temp_${DateTime.now().microsecondsSinceEpoch}',
      'circle_id': _circleId,
      'user_id': user.id,
      'message': text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'sender_info': {'username': user.email?.split('@').first ?? 'You'},
      'is_optimistic': true,
    };

    final withOptimistic = List<Map<String, dynamic>>.from(state.messages)
      ..add(optimisticMessage);

    state = state.copyWith(
      messages: _sortMessages(withOptimistic),
      error: null,
    );

    final response = await _gameService.sendCircleMessage(_circleId, text);
    final success = response['success'] == true;

    if (!success) {
      final rollback = state.messages
          .where((message) => message['id'] != optimisticMessage['id'])
          .toList();
      state = state.copyWith(
        messages: rollback,
        error: response['error']?.toString() ?? 'Failed to send message',
      );
      return;
    }

    final payload = response['message'];
    if (payload is Map<String, dynamic>) {
      _mergeIncomingMessage(_normalizeMessage(payload));
    } else if (payload is Map) {
      _mergeIncomingMessage(_normalizeMessage(Map<String, dynamic>.from(payload)));
    } else {
      final cleaned = state.messages
          .where((message) => message['id'] != optimisticMessage['id'])
          .toList();
      state = state.copyWith(messages: cleaned, error: null);
    }
  }

  List<Map<String, dynamic>> _sortMessages(
    List<Map<String, dynamic>> messages,
  ) {
    final sorted = List<Map<String, dynamic>>.from(messages);
    sorted.sort((a, b) => _parseTime(b).compareTo(_parseTime(a)));
    return sorted;
  }

  DateTime _parseTime(Map<String, dynamic> row) {
    final raw = row['created_at']?.toString();
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.tryParse(raw) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
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

final circleChatsProvider = circleMessagesProvider;
