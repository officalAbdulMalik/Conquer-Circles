import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/subscription/widgets/cancel_subscription_dialog.dart';
import 'package:test_steps/features/subscription/widgets/plan_radial_lines_painter.dart';

class CurrentPlanCard extends StatelessWidget {
  const CurrentPlanCard({
    super.key,
    required this.amount,
    required this.renewalDate,
    required this.onCancelSuccess,
  });

  final String amount;
  final String renewalDate;
  final VoidCallback onCancelSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightBlueColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.blueColor.withValues(alpha: 0.15),
          width: 1.5.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Radiating Lines Background
            Positioned.fill(
              child: CustomPaint(
                painter: PlanRadialLinesPainter(
                  lineColor: AppColors.blueColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Current Plan',
                        style: AppTextStyles.montserrat(
                          size: 18,
                          weight: FontWeight.w600,
                          color: AppColors.textNavy,
                        ),
                      ),
                      8.horizontalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueColor,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'Active',
                          style: AppTextStyles.montserrat(
                            size: 11,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: amount,
                          style: AppTextStyles.montserrat(
                            size: 26,
                            weight: FontWeight.w800,
                            color: AppColors.textNavy,
                          ),
                        ),
                        TextSpan(
                          text: '/yr',
                          style: AppTextStyles.montserrat(
                            size: 15,
                            weight: FontWeight.w500,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  6.verticalSpace,
                  Text(
                    'Renew at $renewalDate',
                    style: AppTextStyles.montserrat(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  20.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () => _handleCancelSubscription(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFF1F3F7),
                        foregroundColor: AppColors.textNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        'Cancel Subscription',
                        style: AppTextStyles.montserrat(
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancelSubscription(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const CancelSubscriptionDialog(),
    );

    if (confirmed == true && context.mounted) {
      onCancelSuccess();
    }
  }
}
