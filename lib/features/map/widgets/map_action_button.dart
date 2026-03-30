import 'package:flutter/material.dart';

enum MapActionType { start, pause, resume, stop }

class MapActionButton extends StatelessWidget {
  final MapActionType type;
  final VoidCallback onTap;

  const MapActionButton({super.key, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D968B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D968B).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  _getText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case MapActionType.start:
        return Icons.play_arrow;
      case MapActionType.pause:
        return Icons.pause;
      case MapActionType.resume:
        return Icons.play_arrow;
      case MapActionType.stop:
        return Icons.stop;
    }
  }

  String _getText() {
    switch (type) {
      case MapActionType.start:
        return 'Start Walk';
      case MapActionType.pause:
        return 'Pause Walk';
      case MapActionType.resume:
        return 'Resume Walk';
      case MapActionType.stop:
        return 'Stop Walk';
    }
  }
}
