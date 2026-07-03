import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/subscription/widgets/current_plan_card.dart';
import 'package:test_steps/features/subscription/widgets/payment_history_list.dart';
import 'package:test_steps/features/subscription/widgets/plan_purchase_header.dart';
import 'package:test_steps/providers/subscription_provider.dart';

class PlanPurchaseView extends ConsumerWidget {
  const PlanPurchaseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can watch subscriptionProvider if needed for state tracking, 
    // but we'll show the mock data requested in the design.
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
