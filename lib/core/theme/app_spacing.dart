import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  AppSpacing._();

  static double get x2 => 2.w;
  static double get x4 => 4.w;
  static double get x6 => 6.w;
  static double get x8 => 8.w;
  static double get x10 => 10.w;
  static double get x12 => 12.w;
  static double get x14 => 14.w;
  static double get x16 => 16.w;
  static double get x18 => 18.w;
  static double get x20 => 20.w;
  static double get x24 => 24.w;
  static double get x28 => 28.w;

  static EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: 20.w,);

  static EdgeInsets cardAll(double value) => EdgeInsets.all(value.w);

  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(horizontal: horizontal.w, vertical: vertical.h);
  }
}
