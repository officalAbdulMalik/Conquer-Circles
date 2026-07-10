import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/settings/widgets/energy_usage_tile.dart';
import 'package:test_steps/models/energy_ledger_entry.dart';
import 'package:test_steps/providers/energy_usage_provider.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';
import 'package:test_steps/widgets/shared/app_screen_header.dart';

class EnergyUsageScreen extends ConsumerWidget {
  const EnergyUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(energyUsageProvider);

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
              onRefresh: () async => ref.refresh(energyUsageProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    12.verticalSpace,
                    const AppScreenHeader(title: 'Energy Usage'),
                    20.verticalSpace,
                    usage.when(
                      data: (data) => _EnergyContent(data: data),
                      loading: () => const _EnergyLoading(),
                      error: (_, __) => const _EnergyError(),
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

class _EnergyContent extends StatelessWidget {
  const _EnergyContent({required this.data});

  final EnergyUsageData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.isEmpty)
          const _EnergyEmpty()
        else
          ...data.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: EnergyUsageTile(
                title: entry.description,
                description: _subtitleForType(entry.type),
                date: _formatWhenWithToday(entry.createdAt),
                amount: entry.amountLabel,
                amountColor: energyAmountColor(entry),
                type: entry.type,
              ),
            );
          }),
      ],
    );
  }
}


class _EnergyLoading extends StatelessWidget {
  const _EnergyLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EnergyEmpty extends StatelessWidget {
  const _EnergyEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.bolt_outlined, size: 40.r, color: AppColors.textSecondary),
          12.verticalSpace,
          Text(
            'No energy activity yet',
            style: AppTextStyles.montserrat(
              size: 15.sp,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          6.verticalSpace,
          Text(
            'Walk to earn energy and attack territories — your history will show up here.',
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

class _EnergyError extends StatelessWidget {
  const _EnergyError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 26.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 38.r, color: AppColors.error),
          12.verticalSpace,
          Text(
            'Could not load energy usage',
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

String _formatWhenWithToday(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(when.year, when.month, when.day);
  
  final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final m = when.minute.toString().padLeft(2, '0');
  final ampm = when.hour < 12 ? 'AM' : 'PM';
  final timeStr = '$h:$m $ampm';

  if (date == today) {
    return 'Today · $timeStr';
  }
  
  final yesterday = today.subtract(const Duration(days: 1));
  if (date == yesterday) {
    return 'Yesterday · $timeStr';
  }

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[when.month - 1]} ${when.day} · $timeStr';
}

String _subtitleForType(String type) {
  switch (type) {
    case 'steps':
      return 'Convert steps to energy';
    case 'step_milestone':
      return 'Bonus for reaching milestone';
    case 'territory_battle':
    case 'territory_assault':
      return 'Attack on nearby rival territory';
    case 'purchase':
      return 'Energy store purchase';
    default:
      return 'Energy ledger adjustment';
  }
}
