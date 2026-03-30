import 'package:flutter/material.dart';

class MapActionControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onLayersToggled;

  const MapActionControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onLayersToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D968B).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF0D968B).withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _ActionButton(icon: Icons.add, onTap: onZoomIn, showBorder: true),
              _ActionButton(icon: Icons.remove, onTap: onZoomOut),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SingleActionButton(
          icon: Icons.near_me,
          onTap: onMyLocation,
          iconColor: const Color(0xFF0D968B),
        ),
        const SizedBox(height: 12),
        _SingleActionButton(
          icon: Icons.layers,
          onTap: onLayersToggled,
          iconColor: const Color(0xFF64748B),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBorder;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: const Color(0xFF0D968B).withValues(alpha: 0.05),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
      ),
    );
  }
}

class _SingleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _SingleActionButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D968B).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF0D968B).withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
