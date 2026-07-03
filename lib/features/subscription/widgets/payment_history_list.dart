import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/subscription/widgets/payment_history_card.dart';

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
