import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StepsProgressPainter extends CustomPainter {
  const StepsProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final strokeWidth = 26.w.clamp(18.0, size.shortestSide * 0.32);
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height - strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = math.pi;
    final sweepAngle = math.pi;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final trackPath = Path()
      ..addArc(rect, startAngle, sweepAngle)
      ..lineTo(
        center.dx + math.cos(startAngle + sweepAngle) * (radius - strokeWidth),
        center.dy + math.sin(startAngle + sweepAngle) * (radius - strokeWidth),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius - strokeWidth),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(trackPath, Paint()..color = const Color(0xFFE8ECF2));

    final activeSweep = sweepAngle * clampedProgress;
    final activePath = Path()
      ..addArc(rect, startAngle, activeSweep)
      ..lineTo(
        center.dx + math.cos(startAngle + activeSweep) * (radius - strokeWidth),
        center.dy + math.sin(startAngle + activeSweep) * (radius - strokeWidth),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius - strokeWidth),
        startAngle + activeSweep,
        -activeSweep,
        false,
      )
      ..close();

    canvas.drawPath(
      activePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF4F6DFF), Color(0xFF3656F5)],
        ).createShader(rect),
    );

    final needleAngle = startAngle + activeSweep;
    final needleStart = Offset(
      center.dx + math.cos(needleAngle) * (radius - strokeWidth + 2.w),
      center.dy + math.sin(needleAngle) * (radius - strokeWidth + 2.w),
    );
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius + 7.w),
      center.dy + math.sin(needleAngle) * (radius + 7.w),
    );

    final needle = Paint()
      ..color = const Color(0xFF2447D8)
      ..strokeWidth = 5.w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(needleStart, needleEnd, needle);

    canvas.drawCircle(
      needleStart,
      4.w,
      Paint()..color = const Color(0xFF2447D8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StepsProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
