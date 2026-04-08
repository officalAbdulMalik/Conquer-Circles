import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_text_styles.dart';

class TerritoryPreviewCard extends StatelessWidget {
  final String title;
  final String location;
  final String imageUrl;

  const TerritoryPreviewCard({
    super.key,
    required this.title,
    required this.location,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      height: 160.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16.h,
            left: 16.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location.toUpperCase(),
                  style: AppTextStyles.style(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 10,
                    weight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
