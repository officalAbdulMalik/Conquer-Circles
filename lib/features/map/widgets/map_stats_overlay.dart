import 'package:flutter/material.dart';

class MapStatsOverlay extends StatelessWidget {
  final String steps;
  final String kcal;
  final String zones;
  final String energy;

  const MapStatsOverlay({
    super.key,
    required this.steps,
    required this.kcal,
    required this.zones,
    required this.energy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            icon: '👟',
            value: steps,
            label: 'Steps',
            color: const Color(0xFF6366F1),
          ),
          _StatItem(
            icon: '🔥',
            value: kcal,
            label: 'kcal',
            color: const Color(0xFFEF4444),
          ),
          _StatItem(
            icon: '🗺️',
            value: zones,
            label: 'Zones',
            color: const Color(0xFF3B82F6),
          ),
          _StatItem(
            icon: '⚡',
            value: energy,
            label: 'Energy',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
