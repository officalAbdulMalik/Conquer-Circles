import 'dart:convert';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all circle, invite, leaderboard, season, and anti-cheat logic.
/// Circles are the unit of gameplay — attacks, leaderboard, and territory
/// visibility are all scoped to players who share at least one circle.
class GameService {
  final _client = Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  // ignore: avoid_print
  void _log(String m, Object e) => print('[GameService.$m] $e');

  // ---------------------------------------------------------------------------
  // CIRCLE CREATION
  // ---------------------------------------------------------------------------

  /// Creates a new circle. Free: 1 max. Premium: 5 max.
  /// Returns { success, circle_id, invite_code }
  /// Call from: CirclesScreen "Create Circle" button
  Future<Map<String, dynamic>> createCircle(
    String name, {
    bool isPrivate = true,
    String? iconUrl,
  }) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    try {
      dynamic res;
      final payload = {
        'p_user_id': user.id,
        'p_name': name,
        'p_is_private': isPrivate,
        if (iconUrl != null) 'p_icon_url': iconUrl,
      };
      try {
        // Preferred signature:
        // create_circle(p_user_id, p_name, p_is_private, p_icon_url)
        // ignore: avoid_print
        print(
          '[GameService.createCircle] Database payload: '
          '${jsonEncode(payload)}',
        );
        res = await _client.rpc('create_circle', params: payload);
      } catch (e) {
        // Backward compatibility with older RPC signature
        final fallbackPayload = {'p_user_id': user.id, 'p_name': name};
        // ignore: avoid_print
        print(
          '[GameService.createCircle] Retrying with legacy payload: '
          '${jsonEncode(fallbackPayload)}',
        );
        res = await _client.rpc('create_circle', params: fallbackPayload);
      }
      final response = Map<String, dynamic>.from(res as Map);
      // ignore: avoid_print
      print(
        '[GameService.createCircle] Database response: '
        '${jsonEncode(response)}',
      );
      return response;
    } catch (e) {
      _log('createCircle', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // CIRCLE INVITES
  // ---------------------------------------------------------------------------

  /// Sends a circle invite to [inviteeId] for [circleId].
  /// Creates invite row + in-app notification for invitee.
  /// Returns { success, circle_name, invite_code }
  /// Call from: CircleScreen "Invite Player" after user search
  Future<Map<String, dynamic>> inviteToCircle({
    required String inviteeId,
    required String circleId,
  }) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    try {
      final res = await _client.rpc(
        'invite_to_circle',
        params: {
          'p_inviter_id': user.id,
          'p_invitee_id': inviteeId,
          'p_circle_id': circleId,
        },
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _log('inviteToCircle', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Returns all pending circle invites for the current user.
  /// Each row: invite_id, circle_id, circle_name, inviter_name, invite_code.
  /// Call from: InvitesScreen / NotificationsScreen on init
  Future<List<Map<String, dynamic>>> getMyCircleInvites() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await _client.rpc(
        'get_circle_invites',
        params: {'p_user_id': user.id},
      );
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      _log('getMyCircleInvites', e);
      return [];
    }
  }

  /// Accepts a circle invite.
  /// On acceptance:
  ///   → User added to circle_members
  ///   → Friend links created with ALL existing members (attack unlocks)
  ///   → Leaderboard entry initialised
  ///   → Owner notified
  /// Returns { success, circle_id, circle_name }
  /// Call from: InvitesScreen "Accept" button
  Future<Map<String, dynamic>> acceptCircleInvite(String inviteId) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    try {
      final res = await _client.rpc(
        'accept_circle_invite',
        params: {'p_invite_id': inviteId, 'p_user_id': user.id},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _log('acceptCircleInvite', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Rejects a circle invite.
  /// Call from: InvitesScreen "Decline" button
  Future<Map<String, dynamic>> rejectCircleInvite(String inviteId) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    try {
      final res = await _client.rpc(
        'reject_circle_invite',
        params: {'p_invite_id': inviteId, 'p_user_id': user.id},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _log('rejectCircleInvite', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // JOIN BY INVITE CODE
  // ---------------------------------------------------------------------------

  /// Joins a circle via its 8-character invite code.
  /// On join: friend links created with all members → attack unlocks instantly.
  /// Returns { success, circle_id, circle_name, member_count }
  /// Call from: JoinCircleScreen "Join" button
  Future<Map<String, dynamic>> joinCircleByCode(String inviteCode) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    try {
      final res = await _client.rpc(
        'join_circle',
        params: {
          'p_user_id': user.id,
          'p_invite_code': inviteCode.toUpperCase(),
        },
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _log('joinCircleByCode', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> requestToJoinCircle(String circleId) async {
    final user = currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }
    if (!_isUuid(circleId)) {
      return {'success': false, 'error': 'Invalid circle ID'};
    }
    try {
      final response = await _client.rpc(
        'request_to_join_circle',
        params: {'p_circle_id': circleId, 'p_requester_id': user.id},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('requestToJoinCircle', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getIncomingCircleJoinRequests() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final rows = await _client
          .from('circle_join_requests')
          .select(
            'id, circle_id, requester_id, status, created_at, '
            'circle:circles!circle_id!inner(id, name, owner_id), '
            'requester:profiles!requester_id(username, full_name, avatar_url)',
          )
          .eq('status', 'pending')
          .eq('circle.owner_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      _log('getIncomingCircleJoinRequests', e);
      return [];
    }
  }

  Future<Map<String, String>> getMyCircleJoinRequestStatuses() async {
    final user = currentUser;
    if (user == null) return {};
    try {
      final rows = await _client
          .from('circle_join_requests')
          .select('circle_id, status')
          .eq('requester_id', user.id);
      return {
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          if (row['circle_id'] != null)
            row['circle_id'].toString(): row['status']?.toString() ?? '',
      };
    } catch (e) {
      _log('getMyCircleJoinRequestStatuses', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> respondToCircleJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    final user = currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }
    try {
      final request = await _client
          .from('circle_join_requests')
          .select(
            'id, circle_id, requester_id, status, '
            'circle:circles!circle_id!inner(owner_id, max_members)',
          )
          .eq('id', requestId)
          .eq('status', 'pending')
          .maybeSingle();
      if (request == null) {
        return {'success': false, 'error': 'Pending request not found'};
      }

      final circle = Map<String, dynamic>.from(request['circle'] as Map? ?? {});
      if (circle['owner_id']?.toString() != user.id) {
        return {'success': false, 'error': 'Only the circle owner can respond'};
      }

      if (accept) {
        final memberRows = await _client
            .from('circle_members')
            .select('user_id')
            .eq('circle_id', request['circle_id']);
        final maxMembers = (circle['max_members'] as num?)?.toInt() ?? 25;
        if (memberRows.length >= maxMembers) {
          return {'success': false, 'error': 'Circle is full'};
        }

        await _client.from('circle_members').upsert({
          'circle_id': request['circle_id'],
          'user_id': request['requester_id'],
          'role': 'member',
        }, onConflict: 'circle_id,user_id');
      }

      final status = accept ? 'accepted' : 'rejected';
      await _client
          .from('circle_join_requests')
          .update({
            'status': status,
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', requestId);

      return {
        'success': true,
        'request_id': requestId,
        'circle_id': request['circle_id'],
        'requester_id': request['requester_id'],
        'status': status,
      };
    } catch (e) {
      _log('respondToCircleJoinRequest', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeCircleMember({
    required String circleId,
    required String memberId,
  }) async {
    final user = currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }
    try {
      final response = await _client.rpc(
        'remove_circle_member',
        params: {
          'p_circle_id': circleId,
          'p_member_id': memberId,
          'p_owner_id': user.id,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('removeCircleMember', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // CIRCLE DATA
  // ---------------------------------------------------------------------------

  /// Returns full circle details + member list with game stats.
  /// Only accessible to circle members.
  /// Call from: CircleDetailScreen on init
  Future<Map<String, dynamic>?> getCircleWithMembers(String circleId) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final res = await _client.rpc(
        'get_circle_with_members',
        params: {'p_circle_id': circleId, 'p_user_id': user.id},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _log('getCircleWithMembers', e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCircleDetails(String circleId) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final res = await _client.functions.invoke(
        'get-circle-details',
        body: {'circle_id': circleId, 'user_id': user.id},
        headers: {
          'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken}',
        },
      );

      if (res.status >= 400) {
        throw Exception('Status ${res.status}: ${res.data}');
      }

      final payload = res.data;
      log('getCircleDetails payload type: $payload');

      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      } else if (payload is String) {
        // Rare case where it's not pre-parsed
        return Map<String, dynamic>.from(jsonDecode(payload));
      }
      return null;
    } catch (e) {
      _log('getCircleDetails', e);
      return null;
    }
  }

  /// Returns all circles the current user belongs to.
  /// Call from: CirclesScreen on init
  Future<List<Map<String, dynamic>>> getMyCircles() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      try {
        final res = await _client
            .from('circle_members')
            .select(
              'circle_id, role, joined_at, '
              'circles(id, name, invite_code, max_members, min_members, owner_id, is_active, is_private)',
            )
            .eq('user_id', user.id);
        return List<Map<String, dynamic>>.from(res as List);
      } catch (_) {
        final res = await _client
            .from('circle_members')
            .select(
              'circle_id, role, joined_at, '
              'circles(id, name, invite_code, max_members, min_members, owner_id, is_active)',
            )
            .eq('user_id', user.id);
        return List<Map<String, dynamic>>.from(res as List);
      }
    } catch (e) {
      _log('getMyCircles', e);
      return [];
    }
  }

  /// Returns all active circles for browsing and joining.
  /// Call from: BrowseCirclesScreen on init
  Future<List<Map<String, dynamic>>> getAllCircles() async {
    try {
      final rows = await _client.rpc(
        'get_all_circles_ranked',
        params: {'p_current_user_id': currentUser?.id},
      );

      return List<Map<String, dynamic>>.from(rows as List).map((row) {
        final map = Map<String, dynamic>.from(row);
        final rawProfiles = map['member_profiles'];
        map['member_profiles'] = rawProfiles is List
            ? List<Map<String, dynamic>>.from(
                rawProfiles.map((p) => Map<String, dynamic>.from(p as Map)),
              )
            : <Map<String, dynamic>>[];
        map['members'] = map['member_count'];
        return map;
      }).toList();
    } catch (e) {
      _log('getAllCircles', e);
      rethrow;
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  /// Leaves a circle. Owner cannot leave.
  /// Call from: CircleDetailScreen "Leave" button
  Future<bool> leaveCircle(String circleId) async {
    final user = currentUser;
    if (user == null) return false;
    try {
      await _client
          .from('circle_members')
          .delete()
          .eq('circle_id', circleId)
          .eq('user_id', user.id)
          .neq('role', 'owner');
      return true;
    } catch (e) {
      _log('leaveCircle', e);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // CIRCLE CHAT
  // ---------------------------------------------------------------------------

  /// Sends a message to a circle's group chat.
  /// Returns the inserted message row when available.
  /// Call from: CircleChatScreen send button
  Future<Map<String, dynamic>> sendCircleMessage(
    String circleId,
    String message,
  ) async {
    final session = _client.auth.currentSession;
    final user = currentUser;
    if (session == null || user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }

    try {
      final response = await _client.functions.invoke(
        'send-circle-message',
        body: {'circle_id': circleId, 'user_id': user.id, 'message': message},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status < 200 || response.status >= 300) {
        return {
          'success': false,
          'error': 'send-circle-message failed: ${response.status}',
        };
      }

      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return {'success': true, 'message': payload};
      }
      if (payload is Map) {
        return {'success': true, 'message': Map<String, dynamic>.from(payload)};
      }

      return {'success': true};
    } catch (e) {
      _log('sendCircleMessage', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetches recent chat messages for a circle.
  Future<List<Map<String, dynamic>>> getCircleMessages(
    String circleId, {
    int limit = 50,
  }) async {
    try {
      dynamic rawMessages;
      try {
        rawMessages = await _client
            .from('circle_messages')
            .select(
              'id, circle_id, user_id, message, sender_info, created_at, '
              'edited_at',
            )
            .eq('circle_id', circleId)
            .order('created_at', ascending: false)
            .limit(limit);
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        rawMessages = await _client
            .from('circle_messages')
            .select('id, circle_id, user_id, message, sender_info, created_at')
            .eq('circle_id', circleId)
            .order('created_at', ascending: false)
            .limit(limit);
      }

      final messages = List<Map<String, dynamic>>.from(rawMessages as List);
      if (messages.isEmpty) return messages;

      final messageIds = messages
          .map((message) => message['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
      final reactionsByMessage = <String, List<Map<String, dynamic>>>{};

      if (messageIds.isNotEmpty) {
        try {
          final rawReactions = await _client
              .from('circle_message_reactions')
              .select('message_id, emoji, user_id, created_at')
              .inFilter('message_id', messageIds);

          for (final reaction in List<Map<String, dynamic>>.from(
            rawReactions as List,
          )) {
            final messageId = reaction['message_id']?.toString();
            if (messageId == null || messageId.isEmpty) continue;
            reactionsByMessage
                .putIfAbsent(messageId, () => <Map<String, dynamic>>[])
                .add(reaction);
          }
        } on PostgrestException catch (e) {
          if (e.code != 'PGRST205') {
            _log('getCircleMessages.reactions', e);
          }
        } catch (e) {
          _log('getCircleMessages.reactions', e);
        }
      }

      return messages.map((message) {
        final row = Map<String, dynamic>.from(message);
        row['circle_message_reactions'] =
            reactionsByMessage[row['id']?.toString()] ??
            <Map<String, dynamic>>[];
        return row;
      }).toList();
    } catch (e) {
      _log('getCircleMessages', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> editCircleMessage(
    String messageId,
    String message,
  ) async {
    final user = currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }
    try {
      final response = await _client.rpc(
        'edit_circle_message',
        params: {
          'p_message_id': messageId,
          'p_user_id': user.id,
          'p_message': message,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('editCircleMessage', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteCircleMessage(String messageId) async {
    final user = currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }
    try {
      final response = await _client.rpc(
        'delete_circle_message',
        params: {'p_message_id': messageId, 'p_user_id': user.id},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('deleteCircleMessage', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Toggle a reaction on a circle chat message. Adds or removes the reaction for the current user.
  Future<Map<String, dynamic>> toggleCircleMessageReaction(
    String messageId,
    String emoji,
  ) async {
    final user = currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Not signed in'};
    }

    try {
      final existingReaction = await _client
          .from('circle_message_reactions')
          .select('id')
          .eq('message_id', messageId)
          .eq('user_id', user.id)
          .eq('emoji', emoji)
          .maybeSingle();

      if (existingReaction != null) {
        final deleteResponse = await _client
            .from('circle_message_reactions')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', user.id)
            .eq('emoji', emoji);

        if (deleteResponse.error != null) {
          return {'success': false, 'error': deleteResponse.error!.message};
        }
      } else {
        final insertResponse = await _client
            .from('circle_message_reactions')
            .insert({
              'message_id': messageId,
              'user_id': user.id,
              'emoji': emoji,
            });
        if (insertResponse.error != null) {
          return {'success': false, 'error': insertResponse.error!.message};
        }
      }

      final updatedReactions = await _client
          .from('circle_message_reactions')
          .select('emoji, user_id')
          .eq('message_id', messageId);

      final reactionRows = List<dynamic>.from(updatedReactions as List? ?? []);
      return {
        'success': true,
        'reactions': reactionRows
            .map<Map<String, dynamic>>((raw) {
              if (raw is Map<String, dynamic>) return raw;
              if (raw is Map) return Map<String, dynamic>.from(raw);
              return <String, dynamic>{};
            })
            .where((raw) => raw.isNotEmpty)
            .toList(),
      };
    } catch (e) {
      _log('toggleCircleMessageReaction', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Real-time stream of messages for a circle.
  /// Call from: CircleChatScreen — subscribe in initState, cancel in dispose
  Stream<List<Map<String, dynamic>>> circleMessageStream(String circleId) {
    return _client
        .from('circle_messages')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ---------------------------------------------------------------------------
  // RAID ALERTS
  // ---------------------------------------------------------------------------

  /// Real-time stream of raid alerts for a circle.
  /// Fires whenever any circle member attacks or captures a tile.
  /// Call from: CircleScreen — subscribe in initState, cancel in dispose
  Stream<List<Map<String, dynamic>>> raidAlertStream(String circleId) {
    return _client
        .from('circle_raid_alerts')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .order('created_at', ascending: false)
        .limit(20)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ---------------------------------------------------------------------------
  // LEADERBOARD
  // ---------------------------------------------------------------------------

  /// Returns leaderboard for a circle in the current (or given) season.
  /// Call from: LeaderboardScreen on init and pull-to-refresh
  Future<List<Map<String, dynamic>>> getCircleLeaderboard(
    String circleId, {
    int? seasonId,
  }) async {
    try {
      final res = await _client.rpc(
        'get_circle_leaderboard',
        params: {'p_circle_id': circleId, 'p_season_id': seasonId},
      );
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      _log('getCircleLeaderboard', e);
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // HOME BASE
  // ---------------------------------------------------------------------------

  /// Sets home base. 30-day change cooldown enforced server-side.
  /// Returns { success, lat, lng } or { success: false, next_change_at }
  /// Call from: MapScreen long-press → "Set as Home Base" confirm
  Future<Map<String, dynamic>> setHomeBase(double lat, double lng) async {
    final user = currentUser;
    if (user == null) return {'success': false, 'error': 'Not signed in'};
    // Never send invalid coordinates: doing so previously started the 30-day
    // cooldown without saving a location, trapping the user.
    if (lat.isNaN ||
        lng.isNaN ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return {'success': false, 'error': 'Invalid home base coordinates'};
    }
    try {
      final res = await _client.rpc(
        'set_home_base',
        params: {'p_user_id': user.id, 'p_lat': lat, 'p_lng': lng},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _log('setHomeBase', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // SEASONS
  // ---------------------------------------------------------------------------

  /// Returns the currently active season.
  /// Call from: HomeScreen / LeaderboardScreen header
  Future<Map<String, dynamic>?> getActiveSeason() async {
    try {
      return await _client
          .from('seasons')
          .select()
          .eq('is_active', true)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      _log('getActiveSeason', e);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // SEASON RECAP
  // ---------------------------------------------------------------------------

  /// Generates and returns the season recap including territory snapshot.
  /// Call from: RecapScreen on init
  Future<Map<String, dynamic>?> getMySeasonRecap(int seasonId) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      await _client.rpc(
        'generate_season_recap',
        params: {'p_user_id': user.id, 'p_season_id': seasonId},
      );
      return await _client
          .from('season_recaps')
          .select()
          .eq('user_id', user.id)
          .eq('season_id', seasonId)
          .maybeSingle();
    } catch (e) {
      _log('getMySeasonRecap', e);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ANTI-CHEAT
  // ---------------------------------------------------------------------------

  /// Returns the current user's trust score and flag status.
  /// Call from: ProfileScreen trust badge
  Future<Map<String, dynamic>?> getTrustStatus() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _client
          .from('profiles')
          .select('trust_score, is_flagged')
          .eq('id', user.id)
          .single();
    } catch (e) {
      _log('getTrustStatus', e);
      return null;
    }
  }
}
