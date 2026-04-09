import 'package:flutter/material.dart';

class QuickActionChips extends StatelessWidget {
  final List<String> chips;
  final Function(String) onChipTapped;
  final List<IconData>? chipIcons;
  final int? selectedIndex;
  final ValueChanged<int>? onChipIndexTapped;
  final bool useCoachStyle;

  const QuickActionChips({
    super.key,
    required this.chips,
    required this.onChipTapped,
    this.chipIcons,
    this.selectedIndex,
    this.onChipIndexTapped,
    this.useCoachStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!useCoachStyle) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: chips.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(chip),
                onPressed: () => onChipTapped(chip),
                backgroundColor: const Color(0xFF0D968B).withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  color: Color(0xFF0D968B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFF0D968B).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    const List<Color> coachColors = <Color>[
      Color(0xFF8A77E8),
      Color(0xFFFFA45E),
      Color(0xFF73D4E8),
      Color(0xFFE9CC6A),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List<Widget>.generate(chips.length, (int index) {
          final String chip = chips[index];
          final bool isSelected = (selectedIndex ?? -1) == index;
          final Color tone = coachColors[index % coachColors.length];
          final IconData? icon = chipIcons != null && index < chipIcons!.length
              ? chipIcons![index]
              : null;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? const Color(0xFF8A77E8) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  onChipTapped(chip);
                  onChipIndexTapped?.call(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8A77E8)
                          : tone.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(
                            0xFF8A77E8,
                          ).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.white : tone,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        chip,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF3A3A44),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
