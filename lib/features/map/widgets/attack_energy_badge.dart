import 'package:flutter/material.dart';

/// Floating Attack Energy badge pinned to the top-right corner of the map.
///
/// Shows current energy / 400 with an amber progress bar.
/// Pulses the icon when energy is 0, shows a MAX pill when full.
class AttackEnergyBadge extends StatefulWidget {
  final int energy;
  final int maxEnergy;

  const AttackEnergyBadge({
    super.key,
    required this.energy,
    this.maxEnergy = 400,
  });

  @override
  State<AttackEnergyBadge> createState() => _AttackEnergyBadgeState();
}

class _AttackEnergyBadgeState extends State<AttackEnergyBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.energy == 0;
    final bool isFull = widget.energy >= widget.maxEnergy;
    final double progress = (widget.energy / widget.maxEnergy).clamp(0.0, 1.0);

    // Amber colour
    const amber = Color(0xFFFF9800);
    const amberDim = Color(0xFF4A3800);

    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC000000), // rgba(0,0,0,0.8)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: amber.withValues(alpha: isEmpty ? 0 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon + number row ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing bolt when empty
              isEmpty
                  ? FadeTransition(
                      opacity: _pulseAnim,
                      child: const Icon(Icons.bolt, color: amber, size: 16),
                    )
                  : const Icon(Icons.bolt, color: amber, size: 16),

              const SizedBox(width: 4),

              Text(
                '${widget.energy}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),

              if (isFull) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MAX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 2),

          // ── Subtitle ─────────────────────────────────────
          Text(
            '/ ${widget.maxEnergy} energy',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          // ── Progress bar ─────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isEmpty ? const Color(0xFF333333) : amberDim,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? const Color(0xFFFFCC00) : amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
