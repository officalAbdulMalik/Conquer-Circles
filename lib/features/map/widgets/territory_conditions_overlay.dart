import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/walk_models.dart';

/// Displays territory energy, protection status, and cooldown on the map.
/// Shows as an overlay positioned near the territory center.
class TerritoryConditionsOverlay extends StatefulWidget {
  final Territory territory;
  final LatLng center; // Position to place the overlay
  final double zoomLevel; // Map zoom for scaling

  const TerritoryConditionsOverlay({
    super.key,
    required this.territory,
    required this.center,
    this.zoomLevel = 15,
  });

  @override
  State<TerritoryConditionsOverlay> createState() =>
      _TerritoryConditionsOverlayState();
}

class _TerritoryConditionsOverlayState extends State<TerritoryConditionsOverlay>
    with TickerProviderStateMixin {
  late AnimationController _cooldownAnimationController;

  @override
  void initState() {
    super.initState();
    _cooldownAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cooldownAnimationController.dispose();
    super.dispose();
  }

  /// Format remaining time as "2.5h", "15m", "30s"
  String _formatTimeRemaining(DateTime? until) {
    if (until == null || !until.isAfter(DateTime.now())) {
      return '';
    }
    final remaining = until.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      final fraction = remaining.inSeconds / 3600.0;
      return '${fraction.toStringAsFixed(1)}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  /// Check if territory is currently protected
  bool _isCurrentlyProtected() {
    final now = DateTime.now();
    if (widget.territory.protectedUntil != null &&
        widget.territory.protectedUntil!.isAfter(now)) {
      return true;
    }
    if (widget.territory.shieldUntil != null &&
        widget.territory.shieldUntil!.isAfter(now)) {
      return true;
    }
    return false;
  }

  /// Check if territory is in cooldown (can't be attacked again)
  bool _isInCooldown() {
    return widget.territory.cooldownUntil != null &&
        widget.territory.cooldownUntil!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─ ENERGY BAR ─────────────────────────────────────────────────────
        _buildEnergyBar(),
        const SizedBox(height: 6),

        // ─ STATUS BADGES ───────────────────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Protection badge
            if (_isCurrentlyProtected()) ...[
              _buildProtectionBadge(),
              const SizedBox(width: 4),
            ],

            // Cooldown badge (pulsing)
            if (_isInCooldown()) ...[
              _buildCooldownBadge(),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  /// Build the energy bar showing remaining territory energy
  Widget _buildEnergyBar() {
    final maxEnergy = 10; // Territory max energy
    final currentEnergy = widget.territory.energy;
    final energyRatio = (currentEnergy / maxEnergy).clamp(0.0, 1.0);

    // Color gradient: green (full) → yellow → red (empty)
    Color energyColor;
    if (energyRatio > 0.66) {
      energyColor = Colors.green;
    } else if (energyRatio > 0.33) {
      energyColor = Colors.orange;
    } else {
      energyColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            '⚡ Energy: $currentEnergy/$maxEnergy',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),

          // Progress bar
          SizedBox(
            width: 80,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: energyRatio,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(energyColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build protection status badge
  Widget _buildProtectionBadge() {
    final timeRemaining = _formatTimeRemaining(widget.territory.protectedUntil ??
        widget.territory.shieldUntil);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Blue for protection
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '🛡️ $timeRemaining',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build cooldown badge (pulsing animation)
  Widget _buildCooldownBadge() {
    final timeRemaining = _formatTimeRemaining(widget.territory.cooldownUntil);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0)
          .animate(_cooldownAnimationController),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B), // Amber for cooldown
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '⏱️ $timeRemaining',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
