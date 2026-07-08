import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/widgets/referral_history_tile.dart';
import 'package:test_steps/features/profile/widgets/referral_step_tile.dart';
import 'package:test_steps/models/referral_summary.dart';
import 'package:test_steps/providers/referral_provider.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';
import 'package:test_steps/widgets/shared/app_screen_header.dart';

class ReferralCodeScreen extends ConsumerWidget {
  const ReferralCodeScreen({super.key});

  static const _steps = [
    {
      'number': '1',
      'title': 'Share Your Code',
      'subtitle': 'Send your code via chat or whatsapp',
    },
    {
      'number': '2',
      'title': 'Friend Signs Up',
      'subtitle': 'They enter your referral code during registration.',
    },
    {
      'number': '3',
      'title': 'Earn Energy',
      'subtitle': 'You instantly receive: +10 Energy for every successful signup.',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(referralSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          AppBackgroundImage(
            height: 250.h,
            color: AppColors.surface.withValues(alpha: 0.72),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(referralSummaryProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    12.verticalSpace,
                    const AppScreenHeader(title: 'Referral'),
                    24.verticalSpace,
                    summaryAsync.when(
                      data: (summary) => _ReferralBody(steps: _steps, summary: summary),
                      loading: () => Padding(
                        padding: EdgeInsets.only(top: 80.h),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const _ReferralError(),
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({required this.steps, required this.summary});

  final List<Map<String, String>> steps;
  final ReferralSummary summary;

  Future<void> _copyCode(BuildContext context) async {
    final message =
        'Join me on the app! Use my referral code ${summary.code} when you sign up.';
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral message copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CodeCard(
          code: summary.code.isEmpty ? '—' : summary.code,
          totalEarned: summary.totalEarned,
          onCopy: summary.code.isEmpty ? null : () => _copyCode(context),
        ),
        28.verticalSpace,
        Text('How It Works', style: AppTextStyles.sectionTitle),
        16.verticalSpace,
        ...steps.map(
          (step) => ReferralStepTile(
            number: step['number']!,
            title: step['title']!,
            subtitle: step['subtitle']!,
          ),
        ),
        24.verticalSpace,
        Text('Energy Earnings History', style: AppTextStyles.sectionTitle),
        14.verticalSpace,
        if (summary.history.isEmpty)
          const _ReferralEmpty()
        else
          ...summary.history.map(
            (event) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ReferralHistoryTile(
                name: event.name,
                time: _formatWhen(event.createdAt),
                amount: event.energyLabel,
              ),
            ),
          ),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.code,
    required this.totalEarned,
    required this.onCopy,
  });

  final String code;
  final int totalEarned;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
      decoration: BoxDecoration(
        color: AppColors.blueColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueColor.withValues(alpha: 0.24),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            code,
            style: AppTextStyles.montserrat(
              size: 34.sp,
              weight: FontWeight.w800,
              color: AppColors.surface,
              height: 1.1,
              letterSpacing: 2,
            ),
          ),
          8.verticalSpace,
          Text(
            'Referral code · $totalEarned energy earned',
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: AppColors.surface.withValues(alpha: 0.88),
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          18.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24.r),
              child: InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(24.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, size: 18.r, color: AppColors.blueColor),
                      8.horizontalSpace,
                      Text(
                        'Copy & Share Code',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          weight: FontWeight.w700,
                          color: AppColors.blueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralEmpty extends StatelessWidget {
  const _ReferralEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 26.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.group_add_outlined, size: 38.r, color: AppColors.textSecondary),
          12.verticalSpace,
          Text(
            'No referrals yet',
            style: AppTextStyles.montserrat(
              size: 15.sp,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          6.verticalSpace,
          Text(
            'Share your code — you’ll earn +10 energy each time a friend signs up with it.',
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 12.sp,
              weight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralError extends StatelessWidget {
  const _ReferralError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 26.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 38.r, color: AppColors.error),
          12.verticalSpace,
          Text(
            'Could not load your referral info',
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 15.sp,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          6.verticalSpace,
          Text(
            'Pull down to try again.',
            style: AppTextStyles.montserrat(
              size: 12.sp,
              weight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatWhen(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final m = when.minute.toString().padLeft(2, '0');
  final ampm = when.hour < 12 ? 'AM' : 'PM';
  return '${months[when.month - 1]} ${when.day} · $h:$m $ampm';
}
