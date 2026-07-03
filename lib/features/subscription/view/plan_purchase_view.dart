import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/subscription_provider.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';

// ── PLAN RADIAL LINES PAINTER ────────────────────────────────────────────────
class PlanRadialLinesPainter extends CustomPainter {
  const PlanRadialLinesPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.9, size.height * 0.1);

    for (int i = 0; i < 12; i++) {
      final angle = math.pi + (i * math.pi / 2) / 12;
      final end = Offset(
        center.dx + math.cos(angle) * size.width * 1.5,
        center.dy + math.sin(angle) * size.width * 1.5,
      );
      canvas.drawLine(center, end, paint);
    }

    for (int r = 1; r <= 5; r++) {
      canvas.drawCircle(center, r * size.width * 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PlanRadialLinesPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

// ── CANCEL SUBSCRIPTION DIALOG ───────────────────────────────────────────────
class CancelSubscriptionDialog extends StatelessWidget {
  const CancelSubscriptionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Stack(
          children: [
            // Close Button at top-right
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textNavy,
                  size: 24.r,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                16.verticalSpace,
                // Red minus warning circle
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 24.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2.5.r),
                    ),
                  ),
                ),
                16.verticalSpace,
                Text(
                  'Confirm Cancellation',
                  style: AppTextStyles.montserrat(
                    size: 20,
                    weight: FontWeight.w800,
                    color: AppColors.textNavy,
                  ),
                ),
                12.verticalSpace,
                Text(
                  "Are you sure you want to cancel your subscription? You'll lose access to premium features at the end of your current billing period.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                24.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.blueColor,
                              width: 1.5.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: Text(
                            'Stay',
                            style: AppTextStyles.montserrat(
                              size: 15,
                              weight: FontWeight.w600,
                              color: AppColors.blueColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.blueColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: Text(
                            'Yes, Confirm',
                            style: AppTextStyles.montserrat(
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── CURRENT PLAN CARD ────────────────────────────────────────────────────────
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

// ── PAYMENT HISTORY CARD ─────────────────────────────────────────────────────
class PaymentHistoryCard extends StatelessWidget {
  const PaymentHistoryCard({
    super.key,
    required this.appId,
    required this.planName,
    required this.date,
    required this.amount,
  });

  final String appId;
  final String planName;
  final String date;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appId,
                  style: AppTextStyles.montserrat(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                ),
                4.verticalSpace,
                Text(
                  planName,
                  style: AppTextStyles.montserrat(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.textNavy,
                  ),
                ),
                4.verticalSpace,
                Text(
                  date,
                  style: AppTextStyles.montserrat(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.montserrat(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.blueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PAYMENT TRANSACTION MODEL ────────────────────────────────────────────────
class PaymentTransaction {
  const PaymentTransaction({
    required this.appId,
    required this.planName,
    required this.date,
    required this.amount,
  });

  final String appId;
  final String planName;
  final String date;
  final String amount;
}

// ── PAYMENT HISTORY LIST ─────────────────────────────────────────────────────
class PaymentHistoryList extends StatelessWidget {
  const PaymentHistoryList({
    super.key,
    required this.transactions,
  });

  final List<PaymentTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: AppTextStyles.montserrat(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.textNavy,
          ),
        ),
        16.verticalSpace,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return PaymentHistoryCard(
              appId: tx.appId,
              planName: tx.planName,
              date: tx.date,
              amount: tx.amount,
            );
          },
        ),
      ],
    );
  }
}

// ── PLAN PURCHASE HEADER ─────────────────────────────────────────────────────
class PlanPurchaseHeader extends StatelessWidget {
  const PlanPurchaseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppCircularBackButton(),
          Expanded(
            child: Text(
              'Plan & Purchase',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
          ),
          SizedBox(width: 34.w),
        ],
      ),
    );
  }
}

// ── MAIN PLAN PURCHASE VIEW ──────────────────────────────────────────────────
class PlanPurchaseView extends ConsumerWidget {
  const PlanPurchaseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(subscriptionProvider);

    final transactions = [
      const PaymentTransaction(
        appId: '#APP-874521',
        planName: 'PRO Conqueror',
        date: 'Jun 19, 2026',
        amount: '\$60',
      ),
      const PaymentTransaction(
        appId: '#APP-732198',
        planName: 'PRO Conqueror',
        date: 'Jun 25, 2025',
        amount: '\$60',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const PlanPurchaseHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurrentPlanCard(
                      amount: '\$60',
                      renewalDate: '18 Jun, 2027',
                      onCancelSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Subscription cancelled successfully.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    24.verticalSpace,
                    PaymentHistoryList(transactions: transactions),
                    24.verticalSpace,
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
