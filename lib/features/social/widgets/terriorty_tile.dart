import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

enum TerritoryStatus { owned, contested, neutral }

/// A single territory tile in the Territory Control grid.
class TerritoryTile extends StatelessWidget {
  final TerritoryStatus status;
  final VoidCallback? onTap;

  const TerritoryTile({
    super.key,
    required this.status,
    this.onTap,
  });

  Color get _color {
    switch (status) {
      case TerritoryStatus.owned:
        return AppColors.tileOwned;
      case TerritoryStatus.contested:
        return AppColors.tileContested;
      case TerritoryStatus.neutral:
        return AppColors.tileNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// The full territory grid map widget.
class TerritoryGrid extends StatelessWidget {
  final List<TerritoryStatus> tiles;
  final int columns;

  const TerritoryGrid({
    super.key,
    required this.tiles,
    this.columns = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tiles
              .map((status) => TerritoryTile(status: status))
              .toList(),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: AppColors.tileOwned, label: 'Owned (22)'),
            const SizedBox(width: 16),
            _Legend(color: AppColors.tileContested, label: 'Contested'),
            const SizedBox(width: 16),
            _Legend(color: AppColors.tileNeutral, label: 'Neutral'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}