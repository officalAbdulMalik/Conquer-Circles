import 'package:flutter/material.dart';

class QuickActionChips extends StatelessWidget {
  final List<String> chips;
  final Function(String) onChipTapped;

  const QuickActionChips({
    super.key,
    required this.chips,
    required this.onChipTapped,
  });

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: const Color(0xFF0D968B).withOpacity(0.1),
              labelStyle: const TextStyle(
                color: Color(0xFF0D968B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF0D968B).withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
