import 'dart:math' as math;
import 'package:flutter/material.dart';

class PlanRadialLinesPainter extends CustomPainter {
  const PlanRadialLinesPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Center at the top-right of the card
    final center = Offset(size.width * 0.9, size.height * 0.1);

    // Draw radiating lines
    for (int i = 0; i < 12; i++) {
      final angle = math.pi + (i * math.pi / 2) / 12;
      final end = Offset(
        center.dx + math.cos(angle) * size.width * 1.5,
        center.dy + math.sin(angle) * size.width * 1.5,
      );
      canvas.drawLine(center, end, paint);
    }

    // Draw concentric arc/circles
    for (int r = 1; r <= 5; r++) {
      canvas.drawCircle(center, r * size.width * 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PlanRadialLinesPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
