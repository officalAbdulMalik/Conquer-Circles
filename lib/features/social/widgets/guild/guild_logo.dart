import 'package:flutter/material.dart';
import 'package:test_steps/core/constants/app_emojis.dart';

class GuildLogo extends StatelessWidget {
  const GuildLogo({
    super.key,
    this.size = 64,
    this.gradA = const Color(0xFF7C6FF7),
    this.gradB = const Color(0xFF38BDF8),
  });

  final double size;
  final Color gradA;
  final Color gradB;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradA, gradB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradA.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          AppEmojis.lightning,
          style: TextStyle(fontSize: size * 0.47),
        ),
      ),
    );
  }
}
