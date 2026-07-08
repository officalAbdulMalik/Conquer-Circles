import 'package:flutter/material.dart';

class AppBackgroundImage extends StatelessWidget {
  AppBackgroundImage({
    super.key,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.asset = 'assets/images/back.png',
  });

  final double? height;
  final Color? color;
  final BoxFit fit;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Image.asset(
        asset,
        fit: fit,
        width: double.infinity,
        height: height,
        color: color,
      ),
    );
  }
}
