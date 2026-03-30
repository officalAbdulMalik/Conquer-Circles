import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/walk_models.dart';
import '../../../providers/map_provider.dart';
import 'attack_toast.dart';

// ---------------------------------------------------------------------------
// Tile Info Bottom Sheet
// ---------------------------------------------------------------------------

/// Shows info about a tapped hex tile and optionally an Attack / Claim button.
///
/// Pass [tile] for claimed territory, or null for an unclaimed tile.
/// [onAttackResult] fires with the RPC result map after a successful attack.
void showTileInfoSheet({
  required BuildContext context,
  required Territory? tile,
  required String? currentUserId,
  required AttackToastController toastController,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TileInfoSheet(
      tile: tile,
      currentUserId: currentUserId,
      toastController: toastController,
    ),
  );
}

class _TileInfoSheet extends ConsumerStatefulWidget {
  final Territory? tile;
  final String? currentUserId;
  final AttackToastController toastController;

  const _TileInfoSheet({
    required this.tile,
    required this.currentUserId,
    required this.toastController,
  });

  @override
  ConsumerState<_TileInfoSheet> createState() => _TileInfoSheetState();
}

class _TileInfoSheetState extends ConsumerState<_TileInfoSheet> {
  bool _loading = false;

  bool get _isOwn => widget.tile?.userId == widget.currentUserId;
  bool get _isNeutral => widget.tile == null;
  bool get _isProtected => widget.tile?.isProtected() ?? false;

  @override
  Widget build(BuildContext context) {
    final territory = widget.tile;

    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
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

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isNeutral
                  ? _NeutralTileContent(
                      onClaim: _handleClaim,
                      loading: _loading,
                    )
                  : _isOwn
                  ? _OwnTileContent(territory: territory!)
                  : _EnemyTileContent(
                      territory: territory!,
                      onAttack: _handleAttack,
                      loading: _loading,
                      isProtected: _isProtected,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAttack() async {
    if (widget.tile == null) return;
    setState(() => _loading = true);

    final result = await ref
        .read(mapProvider.notifier)
        .onEnterTile(widget.tile!.id);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result != null) {
      final action = result['action']?.toString() ?? '';
      final variant = AttackToastController.variantFromAction(action);
      if (variant != null) {
        widget.toastController.show(variant, _messageForResult(result));
      }
      Navigator.pop(context);
    }
  }

  Future<void> _handleClaim() async {
    setState(() => _loading = true);
    // Claiming happens via onEnterTile at walk speed; for manual tap we call with valid speed
    final loc = ref.read(mapProvider).userLocation;
    if (loc == null) {
      setState(() => _loading = false);
      return;
    }
    // Show a hint toast since physical proximity is needed
    widget.toastController.show(
      AttackToastVariant.claimed,
      'Walk into this tile to claim it!',
    );
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  String _messageForResult(Map<String, dynamic> result) {
    final action = result['action']?.toString() ?? '';
    switch (action) {
      case 'claimed':
        return 'Tile claimed! ⚡';
      case 'captured':
        return 'Enemy tile captured!';
      case 'damaged':
        final before = result['energy_before'] ?? '?';
        final after = result['energy_after'] ?? '?';
        return 'Tile damaged: $before → $after energy';
      case 'protected':
        return 'Protected — come back later';
      case 'cooldown':
        return 'Cooldown active — try later';
      case 'no_energy':
        return 'No attack energy — walk more!';
      default:
        return 'Something went wrong';
    }
  }
}

// ---------------------------------------------------------------------------
// Content panels
// ---------------------------------------------------------------------------

class _OwnTileContent extends StatelessWidget {
  final Territory territory;
  const _OwnTileContent({required this.territory});

  @override
  Widget build(BuildContext context) {
    final protected = territory.isProtected();
    final shieldEnd = territory.shieldUntil ?? territory.protectedUntil;
    final energy = territory.energy.clamp(0, 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.flag, color: Color(0xFF2196F3), size: 18),
            const SizedBox(width: 8),
            const Text(
              'Your Territory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Energy bar
        _EnergyBar(current: energy, max: 60, color: const Color(0xFF2196F3)),
        const SizedBox(height: 12),

        // Shield status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: protected
                ? const Color(0xFF9C27B0).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: protected
                  ? const Color(0xFF9C27B0).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                protected ? Icons.shield : Icons.shield_outlined,
                color: protected
                    ? const Color(0xFF9C27B0)
                    : const Color(0xFF757575),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                protected && shieldEnd != null
                    ? 'Protected for ${_formatRemaining(shieldEnd)}'
                    : 'Unprotected',
                style: TextStyle(
                  color: protected
                      ? const Color(0xFF9C27B0)
                      : const Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (territory.lastVisited != null)
          Text(
            'Last visited ${_timeAgo(territory.lastVisited!)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),

        const Spacer(),

        // Reinforce button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: energy < 60 ? () {} : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              side: const BorderSide(color: Color(0xFF2196F3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text(
              'Reinforce',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _formatRemaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return 'yesterday';
  }
}

class _EnemyTileContent extends StatelessWidget {
  final Territory territory;
  final VoidCallback onAttack;
  final bool loading;
  final bool isProtected;
  const _EnemyTileContent({
    required this.territory,
    required this.onAttack,
    required this.loading,
    required this.isProtected,
  });

  @override
  Widget build(BuildContext context) {
    final energy = territory.energy.clamp(0, 60);
    final color = _hexColor(territory.color);
    final shieldEnd = territory.shieldUntil ?? territory.protectedUntil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person, color: Color(0xFFFF5722), size: 18),
            const SizedBox(width: 8),
            Text(
              territory.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _EnergyBar(current: energy, max: 60, color: color),
        const SizedBox(height: 12),

        // Attack energy hint
        const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFFFF9800), size: 14),
            SizedBox(width: 4),
            Text(
              'Your energy is shown on the map ⚡',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),

        const Spacer(),

        // Attack button — disabled if protected or loading
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (isProtected || loading) ? null : onAttack,
            style: ElevatedButton.styleFrom(
              backgroundColor: isProtected
                  ? const Color(0xFF9C27B0)
                  : const Color(0xFFF44336),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isProtected ? Icons.shield : Icons.flash_on, size: 16),
            label: Text(
              isProtected && shieldEnd != null
                  ? 'Protected: ${_remaining(shieldEnd)}'
                  : 'Attack',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _remaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF0D968B);
    }
  }
}

class _NeutralTileContent extends StatelessWidget {
  final VoidCallback onClaim;
  final bool loading;
  const _NeutralTileContent({required this.onClaim, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.hexagon_outlined, color: Color(0xFF94A3B8), size: 18),
            SizedBox(width: 8),
            Text(
              'Unclaimed Territory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EnergyBar(current: 0, max: 60, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 8),
        Text(
          'Walk into this tile at 2–15 km/h to claim it.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.flag, size: 16),
            label: const Text(
              'Claim',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _EnergyBar extends StatelessWidget {
  final int current;
  final int max;
  final Color color;
  const _EnergyBar({
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TILE ENERGY',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$current / $max',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
