import 'package:flutter/material.dart';

class TileActionResult {
  final String action; // 'captured', 'damaged', 'protected', 'cooldown', 'claimed', 'unknown'
  final String tileId;
  final int? energyBefore;
  final int? energyAfter;
  final double? hoursRemaining;
  final String? protectionReason;
  final int? energyNeeded;
  final int? minutesLeft;
  final String? defenderId;
  final String? attackerEnergyLeft;

  const TileActionResult({
    required this.action,
    required this.tileId,
    this.energyBefore,
    this.energyAfter,
    this.hoursRemaining,
    this.protectionReason,
    this.energyNeeded,
    this.minutesLeft,
    this.defenderId,
    this.attackerEnergyLeft,
  });

  factory TileActionResult.fromJson(Map<String, dynamic> json) {
    return TileActionResult(
      action: json['action']?.toString() ?? 'unknown',
      tileId: json['tile_id']?.toString() ?? '',
      energyBefore: json['energy_before'] as int?,
      energyAfter: json['energy_after'] as int?,
      hoursRemaining: (json['hours_remaining'] as num?)?.toDouble(),
      protectionReason: json['reason']?.toString(),
      energyNeeded: json['energy_needed'] as int?,
      minutesLeft: json['minutes_left'] as int?,
      defenderId: json['defender_id']?.toString(),
      attackerEnergyLeft: json['attacker_energy_left']?.toString(),
    );
  }
}

class TileActionFeedback {
  static void handle(BuildContext context, TileActionResult result) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    String message = '';
    Color color = Colors.blue;

    switch (result.action) {
      case 'captured':
        message = 'Territory captured!';
        color = const Color(0xFF10B981);
        break;
      case 'damaged':
        message = 'Tile damaged (${result.energyAfter} energy left)';
        color = const Color(0xFFF59E0B);
        break;
      case 'protected':
        final reason = result.protectionReason == 'walk' ? 'walk shield' : 'protection';
        message = 'Protected by $reason (${result.hoursRemaining?.toStringAsFixed(1)}h left)';
        color = const Color(0xFF6366F1);
        break;
      case 'cooldown':
        message = 'Tile on cooldown (${result.minutesLeft}m left)';
        color = const Color(0xFF64748B);
        break;
      case 'claimed':
        message = 'Territory claimed successfully';
        color = const Color(0xFF10B981);
        break;
      case 'no_energy':
        message = 'Need ${result.energyNeeded} more energy';
        color = const Color(0xFFEF4444);
        break;
      default:
        message = 'Action performed: ${result.action}';
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class AttackResultOverlay {
  static Future<void> show(BuildContext context, TileActionResult result) async {
    // This could also be a dialog or a more complex overlay
    // For now, let's keep it simple as a full-screen semi-transparent overlay
    // that disappears after a few seconds.
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Attack Result',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.action == 'captured') ...[
                  const Icon(Icons.stars, color: Colors.amber, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'VICTORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    'TERRITORY CAPTURED',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ] else if (result.action == 'protected') ...[
                  const Icon(Icons.shield, color: Color(0xFF6366F1), size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'PROTECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${result.hoursRemaining?.toStringAsFixed(1)} hours remaining',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
