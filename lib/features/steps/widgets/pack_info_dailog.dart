import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class PackInfoDialog extends StatelessWidget {
  final String title;
  final String description;
  final String sectionTitle;
  final List<String> bulletPoints;

  const PackInfoDialog({
    super.key,
    this.title = '+1 Additional Circle',
    this.description =
        'Unlock +1 additional Circle to expand your control on the map.',
    this.sectionTitle = 'How it works',
    this.bulletPoints = const [
      'Increases Circle limit by +1',
      'Works instantly after purchase',
      'Each Circle operates independently',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 22, color: Colors.black),
                  ),
                ),
              ],
            ),

            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/icons/info_icon.png',
                width: 80,
                height: 80,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.montserrat(
                  size: 20.sp,
                  color: Colors.black87,
                  weight: FontWeight.w600,
                ),
              ),
            ),

             SizedBox(height: 10.sp),

            // Description
            Center(
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.montserrat(
                  size: 16.sp,
                  color: Colors.grey.shade600,
                  weight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),

             SizedBox(height: 20.sp),

            // Section title
            Text(
              sectionTitle,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: Colors.black87,
                weight: FontWeight.w600,
              ),
            ),

             SizedBox(height: 10.sp),

            // Bullet points
            ...bulletPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: Colors.grey.shade600,
                          weight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
