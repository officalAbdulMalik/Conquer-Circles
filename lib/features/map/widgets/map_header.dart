import 'package:flutter/material.dart';

class MapHeader extends StatelessWidget {
  const MapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Level Indicator
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF7B6FD4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '15',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'FitWarrior',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Elite Runner',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // XP Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 2450 / 3000,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // XP Text
          Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFF7B6FD4), size: 16),
              const SizedBox(width: 4),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '2,450',
                      style: TextStyle(
                        color: Color(0xFF7B6FD4),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' / 3,000 XP',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
