import 'package:flutter/material.dart';

/// Pill badge showing current speed in km/h.
/// Fades in when [visible] is true (while walking), fades out otherwise.
///
/// Color logic:
///   Grey  — below 2 km/h  (too slow)
///   Green — 2–15 km/h     (valid attack speed)
///   Red   — above 15 km/h (vehicle detected)
class SpeedIndicatorBadge extends StatelessWidget {
  final double speedKmh;
  final bool visible;

  const SpeedIndicatorBadge({
    super.key,
    required this.speedKmh,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final _SpeedZone zone = _speedZone(speedKmh);

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: zone.bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: zone.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: zone.glow.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(zone.icon, color: zone.fg, size: 13),
              const SizedBox(width: 5),
              Text(
                '${speedKmh.toStringAsFixed(1)} km/h',
                style: TextStyle(
                  color: zone.fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                zone.label,
                style: TextStyle(
                  color: zone.fg.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SpeedZone _speedZone(double kmh) {
    if (kmh < 2) return _SpeedZone.slow;
    if (kmh <= 15) return _SpeedZone.valid;
    return _SpeedZone.fast;
  }
}

class _SpeedZone {
  final Color fg;
  final Color bg;
  final Color border;
  final Color glow;
  final IconData icon;
  final String label;

  const _SpeedZone({
    required this.fg,
    required this.bg,
    required this.border,
    required this.glow,
    required this.icon,
    required this.label,
  });

  static const slow = _SpeedZone(
    fg: Color(0xFF94A3B8),
    bg: Color(0xFF1E293B),
    border: Color(0xFF334155),
    glow: Color(0xFF64748B),
    icon: Icons.directions_walk,
    label: 'too slow',
  );

  static const valid = _SpeedZone(
    fg: Color(0xFF4CAF50),
    bg: Color(0xFF0F2D10),
    border: Color(0xFF2E7D32),
    glow: Color(0xFF4CAF50),
    icon: Icons.directions_walk,
    label: '✓ attack',
  );

  static const fast = _SpeedZone(
    fg: Color(0xFFF44336),
    bg: Color(0xFF2D0F0F),
    border: Color(0xFFC62828),
    glow: Color(0xFFF44336),
    icon: Icons.directions_car,
    label: 'too fast',
  );
}
