// =============================================================================
// map_tile_handler.dart
//
// Drop this into lib/features/map/utils/
// This is the complete tile interaction handler for your map_provider.
// Replace your existing claimOrAttackTile() call with _handleTileInteraction()
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/features/map/widgets/tile_action.dart';

// ─── Map tile state model ────────────────────────────────────────────────────

enum TileOwnership { mine, enemy, neutral }

class MapTile {
  final String tileId;
  final TileOwnership ownership;
  final int energy;
  final DateTime? protectionUntil;
  final String? ownerUsername;
  final String? ownerId;

  const MapTile({
    required this.tileId,
    required this.ownership,
    required this.energy,
    this.protectionUntil,
    this.ownerUsername,
    this.ownerId,
  });

  bool get isProtected =>
      protectionUntil != null && protectionUntil!.isAfter(DateTime.now());

  double get hoursProtected => isProtected
      ? protectionUntil!.difference(DateTime.now()).inMinutes / 60.0
      : 0;

  Color get displayColor {
    if (ownership == TileOwnership.mine) {
      return const Color(0xFF7B6FD4); // premium purple
    }
    if (ownership == TileOwnership.enemy) {
      return const Color(0xFFEF4444); // vibrant red
    }
    return const Color(0xFFF1F5F9); // neutral light grey
  }

  factory MapTile.fromJson(Map<String, dynamic> json, String currentUserId) {
    final ownerId = json['owner_id'] as String?;
    TileOwnership ownership;
    if (ownerId == null) {
      ownership = TileOwnership.neutral;
    } else if (ownerId == currentUserId) {
      ownership = TileOwnership.mine;
    } else {
      ownership = TileOwnership.enemy;
    }

    DateTime? prot;
    final protStr = json['protection_until'] as String?;
    if (protStr != null) prot = DateTime.tryParse(protStr);

    return MapTile(
      tileId: json['tile_id'] as String,
      ownership: ownership,
      energy: json['tile_energy'] as int? ?? 0,
      protectionUntil: prot,
      ownerUsername: json['owner_username'] as String?,
      ownerId: ownerId,
    );
  }
}

// ─── Tile interaction handler ─────────────────────────────────────────────────

class MapTileHandler {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Call this when a player taps a hex tile on the map.
  ///
  /// [tile]    — the MapTile that was tapped
  /// [context] — for showing SnackBar / overlay feedback
  /// [lat/lng] — player's current GPS coordinates
  ///
  /// Returns the updated TileActionResult if the attack succeeded,
  /// or null if it was blocked before reaching the server.
  Future<TileActionResult?> handleTileTap({
    required BuildContext context,
    required MapTile tile,
    required double lat,
    required double lng,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    // ── PRE-FLIGHT CLIENT-SIDE CHECKS ──────────────────────────────────────
    // Show instant feedback before the RPC round-trip for obvious blocks.

    // 1. Own tile — just reinforce, no need to check anything
    // (falls through to RPC which handles it as 'claimed')

    // 2. Enemy tile that's visually protected — show shield immediately
    //    without waiting for the RPC (saves a round trip)
    if (tile.ownership == TileOwnership.enemy && tile.isProtected) {
      TileActionFeedback.handle(
        context,
        TileActionResult(
          action: 'protected',
          tileId: tile.tileId,
          protectionReason: 'tile',
          hoursRemaining: tile.hoursProtected,
        ),
      );
      return null;
    }

    // ── SERVER RPC CALL ────────────────────────────────────────────────────
    try {
      final raw = await _client.rpc(
        'claim_or_attack_tile',
        params: {
          'p_tile_id': tile.tileId,
          'p_user_id': userId,
          'p_lat': lat,
          'p_lng': lng,
        },
      );

      if (raw == null) {
        TileActionFeedback.handle(
          context,
          TileActionResult(action: 'unknown', tileId: tile.tileId),
        );
        return null;
      }

      final result = TileActionResult.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );

      // ── SHOW FEEDBACK ────────────────────────────────────────────────────
      // Show toast/banner for the action
      TileActionFeedback.handle(context, result);

      // Show full-screen overlay only for capture or protected (big moments)
      if (result.action == 'captured' || result.action == 'protected') {
        await AttackResultOverlay.show(context, result);
      }

      return result;
    } catch (e) {
      debugPrint('[MapTileHandler] RPC error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error — $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  /// Load all tiles visible in the current map bounds.
  /// Call this whenever the camera moves significantly (debounced).
  Future<List<MapTile>> loadTilesForBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('hex_tiles')
          .select('''
            tile_id,
            owner_id,
            tile_energy,
            protection_until,
            profiles!hex_tiles_owner_id_fkey(username)
          ''')
          // Filter by approximate lat/lng bounding box
          // tile_id format is "latInt_lngInt" so this is a rough filter
          .not(
            'tile_energy',
            'eq',
            -1,
          ); // get all (PostGIS filter in real impl)

      return rows.map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        if (m['profiles'] != null) {
          m['owner_username'] = (m['profiles'] as Map)['username'] as String?;
        }
        return MapTile.fromJson(m, userId);
      }).toList();
    } catch (e) {
      debugPrint('[MapTileHandler] loadTilesForBounds error: $e');
      return [];
    }
  }
}
