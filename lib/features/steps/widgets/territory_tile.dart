import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class TerritoryHistoryCard extends StatelessWidget {
  const TerritoryHistoryCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: AppBorders.raised(),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    width: 100.w,
                    height: 100.h,
                    child: CustomPaint(painter: TerritoryThumbnailPainter()),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+0.42 km² Captured',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 16.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                      5.verticalSpace,
                      Text(
                        'Near Central Park',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textNavy,
                          weight: FontWeight.w400,
                        ),
                      ),
                      5.verticalSpace,
                      Text(
                        'Today · 8:42 PM',
                        style: AppTextStyles.montserrat(
                          size: 12.sp,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            Padding(
              padding: EdgeInsets.only(left: 8.sp),
              child: _HistoryMetricRow(),
            ),
          ],
        ),
      ),
    );
  }
}

class TerritoryThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _paintMapBase(canvas, size, showLabels: false);
    _paintPolyline(
      canvas,
      [
        Offset(size.width * 0.24, size.height * 0.05),
        Offset(size.width * 0.58, size.height * 0.30),
        Offset(size.width * 0.48, size.height * 0.70),
        Offset(size.width * 0.78, size.height * 0.92),
      ],
      const Color(0xFF5169FF),
      2.2,
    );
    _paintLocationMarker(
      canvas,
      size,
      Offset(size.width * 0.28, size.height * 0.24),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HistoryMetricRow extends StatelessWidget {
  const _HistoryMetricRow();

  @override
  Widget build(BuildContext context) {
    const metrics = [
      ('8,420', 'Steps'),
      ('8.72km', 'Distance'),
      ('45:10', 'Duration'),
      ('42', 'Energy'),
    ];

    return Row(
      children: List.generate(metrics.length, (index) {
        final metric = metrics[index];

        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: index == 0
                  ? null
                  : Border(
                      left: BorderSide(
                        color: AppColors.borderColor,
                        width: 1.w,
                      ),
                    ),
            ),
            child: Column(
              children: [
                Text(
                  metric.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                5.verticalSpace,
                Text(
                  metric.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

void _paintMapBase(Canvas canvas, Size size, {required bool showLabels}) {
  final bg = Paint()..color = const Color(0xFFF0F4FA);
  canvas.drawRect(Offset.zero & size, bg);

  final parkPaint = Paint()..color = const Color(0xFF9BE3BB);
  canvas.drawCircle(
    Offset(size.width * -0.06, size.height * 0.65),
    size.width * 0.42,
    parkPaint,
  );

  final buildingPaint = Paint()..color = const Color(0xFFD9DEE8);
  final buildingStroke = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final random = math.Random(2);
  for (var i = 0; i < 80; i++) {
    final w = (12 + random.nextDouble() * 34) * (size.width / 335);
    final h = (8 + random.nextDouble() * 42) * (size.height / 478);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, buildingPaint);
    canvas.drawRRect(rect, buildingStroke);
  }

  final roadPaint = Paint()
    ..color = const Color(0xFFB7C2D1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.055
    ..strokeCap = StrokeCap.round;
  final roadHighlight = Paint()
    ..color = const Color(0xFFE8EDF5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.038
    ..strokeCap = StrokeCap.round;

  final mainRoad = [
    Offset(size.width * 0.24, -10),
    Offset(size.width * 0.30, size.height * 0.25),
    Offset(size.width * 0.48, size.height * 0.55),
    Offset(size.width * 0.56, size.height + 10),
  ];
  _paintPolyline(canvas, mainRoad, roadPaint.color, roadPaint.strokeWidth);
  _paintPolyline(
    canvas,
    mainRoad,
    roadHighlight.color,
    roadHighlight.strokeWidth,
  );

  _paintPolyline(
    canvas,
    [
      Offset(-10, size.height * 0.08),
      Offset(size.width * 0.45, size.height * 0.10),
      Offset(size.width + 8, size.height * 0.06),
    ],
    roadHighlight.color,
    size.width * 0.034,
  );
  _paintPolyline(
    canvas,
    [
      Offset(size.width * 0.36, size.height * 0.58),
      Offset(size.width * 0.76, size.height * 0.58),
      Offset(size.width + 8, size.height * 0.64),
    ],
    roadHighlight.color,
    size.width * 0.034,
  );

  if (showLabels) {
    _paintRotatedLabel(
      canvas,
      'Eldagh Rd',
      Offset(size.width * 0.24, size.height * 0.26),
      -1.75,
    );
    _paintRotatedLabel(
      canvas,
      'Eldagh Rd',
      Offset(size.width * 0.50, size.height * 0.80),
      -1.55,
    );
    _paintLabel(
      canvas,
      'The City College\nOf Art And Science',
      Offset(size.width * 0.34, size.height * 0.15),
    );
  }
}

void paintTerritoryShapes(Canvas canvas, Size size) {
  _paintPolygon(canvas, [
    Offset(size.width * 0.27, size.height * 0.09),
    Offset(size.width * 0.50, size.height * 0.07),
    Offset(size.width * 0.61, size.height * 0.28),
    Offset(size.width * 0.34, size.height * 0.37),
  ], const Color(0xFFFF5E57));
  _paintPolygon(canvas, [
    Offset(size.width * 0.50, size.height * 0.07),
    Offset(size.width * 0.70, size.height * 0.01),
    Offset(size.width * 0.79, size.height * 0.14),
    Offset(size.width * 0.72, size.height * 0.25),
    Offset(size.width * 0.58, size.height * 0.21),
  ], const Color(0xFF5169FF));
  _paintPolygon(canvas, [
    Offset(size.width * 0.65, size.height * 0.30),
    Offset(size.width * 0.82, size.height * 0.26),
    Offset(size.width * 0.77, size.height * 0.52),
    Offset(size.width * 0.60, size.height * 0.49),
  ], const Color(0xFF20B969));
  _paintPolygon(canvas, [
    Offset(size.width * 0.48, size.height * 0.55),
    Offset(size.width * 0.93, size.height * 0.64),
    Offset(size.width * 0.86, size.height * 0.88),
    Offset(size.width * 0.57, size.height * 0.78),
  ], const Color(0xFFFFB31F));
  _paintPolygon(canvas, [
    Offset(size.width * 0.78, size.height * 0.80),
    Offset(size.width * 0.99, size.height * 0.87),
    Offset(size.width * 0.95, size.height * 0.99),
    Offset(size.width * 0.77, size.height * 0.94),
  ], const Color(0xFFFFB31F));
}

void _paintPolygon(Canvas canvas, List<Offset> points, Color color) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.78));
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

void _paintLocationMarker(Canvas canvas, Size size, Offset center) {
  canvas.drawCircle(
    center,
    size.width * 0.075,
    Paint()..color = Colors.white.withValues(alpha: 0.82),
  );
  canvas.drawCircle(center, size.width * 0.045, Paint()..color = Colors.white);
  canvas.drawCircle(
    center,
    size.width * 0.022,
    Paint()..color = const Color(0xFF5169FF),
  );
}

void _paintPolyline(
  Canvas canvas,
  List<Offset> points,
  Color color,
  double width,
) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

void _paintLabel(Canvas canvas, String text, Offset offset) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF7B8493),
        fontFamily: 'Montserrat',
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 110.w);
  painter.paint(canvas, offset);
}

void _paintRotatedLabel(
  Canvas canvas,
  String text,
  Offset offset,
  double angle,
) {
  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  canvas.rotate(angle);
  _paintLabel(canvas, text, Offset.zero);
  canvas.restore();
}

class TerritoryMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _paintMapBase(canvas, size, showLabels: true);
    paintTerritoryShapes(canvas, size);
    _paintLocationMarker(
      canvas,
      size,
      Offset(size.width * 0.69, size.height * 0.76),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
