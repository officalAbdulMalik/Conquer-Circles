import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class AttackLogEntry {
  final String tileId;
  final String
  action; // 'captured', 'damaged', 'protected', 'cooldown', 'claimed'
  final int? energyBefore;
  final int? energyAfter;
  final DateTime timestamp;
  final bool isDefence; // true when someone attacked YOUR tile

  const AttackLogEntry({
    required this.tileId,
    required this.action,
    this.energyBefore,
    this.energyAfter,
    required this.timestamp,
    this.isDefence = false,
  });

  factory AttackLogEntry.fromJson(Map<String, dynamic> json) {
    return AttackLogEntry(
      tileId: json['tile_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      energyBefore: json['energy_before'] as int?,
      energyAfter: json['energy_after'] as int?,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isDefence: json['is_defence'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider (simple async fetch)
// ---------------------------------------------------------------------------

final attackHistoryProvider = FutureProvider.autoDispose<List<AttackLogEntry>>((
  ref,
) async {
  // Reads from tile_attack_log via Supabase
  final svc = SupabaseService();
  final user = svc.currentUser;
  if (user == null) return [];

  try {
    final rows = await Supabase.instance.client
        .from('tile_attack_log')
        .select()
        .or('attacker_id.eq.${user.id},defender_id.eq.${user.id}')
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List).map((r) {
      final isDefence =
          r['defender_id'] == user.id && r['attacker_id'] != user.id;
      return AttackLogEntry(
        tileId: r['tile_id']?.toString() ?? '',
        action: r['action']?.toString() ?? '',
        energyBefore: r['energy_before'] as int?,
        energyAfter: r['energy_after'] as int?,
        timestamp: r['created_at'] != null
            ? DateTime.parse(r['created_at'] as String)
            : DateTime.now(),
        isDefence: isDefence,
      );
    }).toList();
  } catch (e) {
    return [];
  }
});

// ---------------------------------------------------------------------------
// Sheet entry point
// ---------------------------------------------------------------------------

void showAttackHistorySheet(BuildContext context, {required int attackEnergy}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AttackHistorySheet(attackEnergy: attackEnergy),
  );
}

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

class _AttackHistorySheet extends ConsumerWidget {
  final int attackEnergy;
  const _AttackHistorySheet({required this.attackEnergy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attackHistoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attack History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your recent tile battles',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Energy counter badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: Color(0xFFFF9800),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$attackEnergy',
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            // List
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF9800)),
                ),
                error: (_, __) => _EmptyState(),
                data: (entries) => entries.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: entries.length,
                        itemBuilder: (ctx, i) =>
                            _AttackLogRow(entry: entries[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log row
// ---------------------------------------------------------------------------

class _AttackLogRow extends StatelessWidget {
  final AttackLogEntry entry;
  const _AttackLogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final config = _rowConfig(entry.action, entry.isDefence);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(config.icon, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),

          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.tileId.length > 6
                          ? entry.tileId.substring(0, 6).toUpperCase()
                          : entry.tileId.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ResultBadge(label: config.badge, color: config.badgeColor),
                  ],
                ),
                if (entry.energyBefore != null &&
                    entry.energyAfter != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Energy: ${entry.energyBefore} → ${entry.energyAfter}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Time
          Text(
            _timeAgo(entry.timestamp),
            style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
          ),
        ],
      ),
    );
  }

  _RowConfig _rowConfig(String action, bool isDefence) {
    if (isDefence) {
      return _RowConfig(
        icon: '🛡️',
        iconBg: const Color(0xFF9C27B0).withValues(alpha: 0.2),
        badge: 'DEFENDED',
        badgeColor: const Color(0xFF9C27B0),
        filled: true,
      );
    }
    switch (action) {
      case 'captured':
        return _RowConfig(
          icon: '⚔️',
          iconBg: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          badge: 'CAPTURED',
          badgeColor: const Color(0xFF4CAF50),
          filled: true,
        );
      case 'damaged':
        return _RowConfig(
          icon: '💥',
          iconBg: const Color(0xFFFF5722).withValues(alpha: 0.2),
          badge: 'DAMAGED',
          badgeColor: const Color(0xFFFF5722),
          filled: false,
        );
      case 'claimed':
        return _RowConfig(
          icon: '🏴',
          iconBg: const Color(0xFF2196F3).withValues(alpha: 0.2),
          badge: 'CLAIMED',
          badgeColor: const Color(0xFF2196F3),
          filled: true,
        );
      default:
        return _RowConfig(
          icon: '⚡',
          iconBg: const Color(0xFF757575).withValues(alpha: 0.2),
          badge: action.toUpperCase(),
          badgeColor: const Color(0xFF757575),
          filled: false,
        );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return 'Yesterday';
  }
}

class _RowConfig {
  final String icon;
  final Color iconBg;
  final String badge;
  final Color badgeColor;
  final bool filled;
  const _RowConfig({
    required this.icon,
    required this.iconBg,
    required this.badge,
    required this.badgeColor,
    required this.filled,
  });
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ResultBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF334155), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No battles yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Walk into a friend's territory\nto start attacking",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
