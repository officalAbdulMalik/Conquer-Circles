import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/wearable_provider.dart';
import 'package:test_steps/services/dashboard_service.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class WearableSyncScreen extends ConsumerStatefulWidget {
  const WearableSyncScreen({super.key, required this.currentSteps});

  final int currentSteps;

  @override
  ConsumerState<WearableSyncScreen> createState() => _WearableSyncScreenState();
}

class _WearableSyncScreenState extends ConsumerState<WearableSyncScreen> {
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  String get _watchLabel => _isIOS ? 'Apple Watch' : 'watch';
  String get _healthLabel => _isIOS ? 'Apple Health' : 'Health Connect';

  @override
  Widget build(BuildContext context) {
    ref.listen<WearableState>(wearableProvider, (previous, next) {
      if (previous?.isConnected != true && next.isConnected) {
        ref.read(dashboardProvider.notifier).loadDashboard(force: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Steps synced — ${_formatCount(next.syncedSteps)} steps updated.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    final wearableState = ref.watch(wearableProvider);
    final stepsLabel = _formatCount(
      wearableState.syncedSteps > 0
          ? wearableState.syncedSteps
          : widget.currentSteps,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 260.h,
              color: AppColors.surface.withValues(alpha: 0.72),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppCircularBackButton(),
                        24.verticalSpace,
                        Text(
                          'Connect $_watchLabel',
                          style: AppTextStyles.montserrat(
                            size: 26.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w800,
                          ),
                        ),
                        8.verticalSpace,
                        Text(
                          'Sync your $_watchLabel to keep today\'s steps and '
                          'energy updated.',
                          style: AppTextStyles.montserrat(
                            size: 14.sp,
                            color: AppColors.textSecondary,
                            weight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                        24.verticalSpace,
                        _WearableSyncCard(
                          progress: wearableState.progress,
                          connected: wearableState.isConnected,
                          stepsLabel: stepsLabel,
                          watchLabel: _watchLabel,
                          healthLabel: _healthLabel,
                        ),
                        16.verticalSpace,
                        _HealthInfoCard(
                          watchLabel: _watchLabel,
                          healthLabel: _healthLabel,
                        ),
                        16.verticalSpace,
                        _SyncStatusList(
                          stage: wearableState.stage,
                          healthLabel: _healthLabel,
                        ),
                        if (wearableState.error != null) ...[
                          12.verticalSpace,
                          _WearableErrorBanner(message: wearableState.error!),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  child: PrimaryButton(
                    label: wearableState.isConnected
                        ? 'Sync Again'
                        : wearableState.stage == WearableSyncStage.failed
                        ? 'Try Again'
                        : 'Connect $_watchLabel',
                    isLoading: wearableState.isConnecting,
                    onTap: wearableState.isConnecting
                        ? null
                        : () => ref
                              .read(wearableProvider.notifier)
                              .connectAndSync(currentSteps: widget.currentSteps),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _WearableSyncCard extends StatelessWidget {
  const _WearableSyncCard({
    required this.progress,
    required this.connected,
    required this.stepsLabel,
    required this.watchLabel,
    required this.healthLabel,
  });

  final double progress;
  final bool connected;
  final String stepsLabel;
  final String watchLabel;
  final String healthLabel;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: [
          Container(
            width: 86.w,
            height: 86.w,
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFFE8FBEF)
                  : const Color(0xFFEAF1FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected ? Icons.watch_rounded : Icons.watch_outlined,
              size: 44.sp,
              color: connected ? AppColors.success : AppColors.blueColor,
            ),
          ),
          18.verticalSpace,
          Text(
            connected ? '$watchLabel Connected' : 'Ready to connect',
            style: AppTextStyles.montserrat(
              size: 18.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
          8.verticalSpace,
          Text(
            '$stepsLabel steps from $healthLabel',
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          18.verticalSpace,
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: constraints.maxWidth * progress,
                    height: 8.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5169FF), Color(0xFF53E4F3)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              );
            },
          ),
          10.verticalSpace,
          Text(
            '$percent%',
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains that watch steps arrive through the OS health store, so no
/// Bluetooth pairing / device picker is needed.
class _HealthInfoCard extends StatelessWidget {
  const _HealthInfoCard({required this.watchLabel, required this.healthLabel});

  final String watchLabel;
  final String healthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF1FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 20.sp,
              color: AppColors.blueColor,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connects through $healthLabel',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'Your $watchLabel already syncs steps to $healthLabel. '
                  'Just allow access and we\'ll pull them in — no Bluetooth '
                  'pairing needed.',
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.4,
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

class _SyncStatusList extends StatelessWidget {
  const _SyncStatusList({required this.stage, required this.healthLabel});

  final WearableSyncStage stage;
  final String healthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: [
          _SyncStatusRow(
            label: 'Requesting $healthLabel access',
            complete: _isComplete(WearableSyncStage.requestingAccess),
            active: stage == WearableSyncStage.requestingAccess,
          ),
          14.verticalSpace,
          _SyncStatusRow(
            label: 'Reading watch steps',
            complete: _isComplete(WearableSyncStage.readingSteps),
            active: stage == WearableSyncStage.readingSteps,
          ),
          14.verticalSpace,
          _SyncStatusRow(
            label: 'Updating dashboard',
            complete: _isComplete(WearableSyncStage.updatingDashboard),
            active: stage == WearableSyncStage.updatingDashboard,
          ),
        ],
      ),
    );
  }

  bool _isComplete(WearableSyncStage syncStage) {
    if (stage == WearableSyncStage.failed || stage == WearableSyncStage.idle) {
      return false;
    }
    if (stage == WearableSyncStage.connected) return true;
    return stage.index > syncStage.index;
  }
}

class _WearableErrorBanner extends StatelessWidget {
  const _WearableErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.w),
      ),
      child: Text(
        message,
        style: AppTextStyles.montserrat(
          size: 12.sp,
          color: const Color(0xFF991B1B),
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({
    required this.label,
    required this.complete,
    this.active = false,
  });

  final String label;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (complete) {
      leading = Icon(
        Icons.check_circle_rounded,
        size: 20.sp,
        color: AppColors.success,
      );
    } else if (active) {
      leading = SizedBox(
        width: 20.sp,
        height: 20.sp,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.blueColor),
        ),
      );
    } else {
      leading = Icon(
        Icons.radio_button_unchecked_rounded,
        size: 20.sp,
        color: AppColors.textSecondary,
      );
    }

    return Row(
      children: [
        leading,
        10.horizontalSpace,
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: active || complete
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              weight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
