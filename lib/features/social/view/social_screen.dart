import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/social/view/create_circle_onboarding_view.dart';
import 'package:test_steps/features/social/widgets/chat_preview.dart';
import 'package:test_steps/features/social/widgets/circle_card.dart';
import 'package:test_steps/features/social/widgets/leader_board.dart';
import 'package:test_steps/features/social/widgets/ranking.dart';
import 'package:test_steps/features/social/widgets/red_alerts.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

class CirclesScreen extends ConsumerStatefulWidget {
  final String? circleId; // New parameter to accept circle ID
  const CirclesScreen({super.key, this.circleId});

  @override
  ConsumerState<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends ConsumerState<CirclesScreen> {
  @override
  void initState() {
    super.initState();
    // No manual fetch needed, circleDetailsProvider handles it.
  }

  @override
  Widget build(BuildContext context) {
    final String? activeCircleId =
        widget.circleId ??
        ref
            .watch(circlesProvider)
            .circles
            .firstOrNull?['circle_id']
            ?.toString();

    AsyncValue<Map<String, dynamic>?>? circleDetailsAsync;
    if (activeCircleId != null) {
      circleDetailsAsync = ref.watch(circleDetailsProvider(activeCircleId));
    }

    Map<String, dynamic>? circleData;
    List<dynamic>? leaderboardData;

    if (circleDetailsAsync != null && circleDetailsAsync.hasValue) {
      final data = circleDetailsAsync.value;
      if (data != null) {
        circleData = data['circle'] as Map<String, dynamic>?;
        leaderboardData = data['leaderboard'] as List<dynamic>?;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circles'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.fillColor, AppColors.bgLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

                // SeasonCountdownCard(
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) =>
                //             const SeasonRecapView(seasonId: 4, seasonName: '4'),
                //       ),
                //     );
                //   },
                // ),
                // 16.verticalSpace,

                if (circleDetailsAsync?.isLoading ?? false)
                  const _ShimmerLoading()
                else ...[
                  /// CIRCLE CARD
                  GuildCard(circle: circleData, leaderboard: leaderboardData),

                  16.verticalSpace,

                  /// LEADERBOARD
                  LeaderboardCard(leaderboard: leaderboardData),

                  16.verticalSpace,

                  /// SPECIAL RANKINGS
                  const SpecialRankingsSection(),

                  16.verticalSpace,
                  RaidAlertsCard(),
                  16.verticalSpace,

                  /// CHAT PREVIEW
                  CircleChatCard(),

                  20.verticalSpace,

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Create a New Circle',
                      backgroundColor: AppColors.brandPurple,
                      textStyle: AppTextStyles.buttonLabel.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateCircleOnboardingView(),
                          ),
                        );
                      },
                    ),
                  ),

                  10.verticalSpace,

                  /// JOIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Browse & Join Other Circles',
                      variant: AppButtonVariant.outlined,
                      backgroundColor: AppColors.brandPurple,
                      borderColor: AppColors.brandPurple.withValues(alpha: 0.3),
                      textStyle: AppTextStyles.buttonLabel.copyWith(
                        color: AppColors.brandPurple,
                        fontSize: 14.sp,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllCirclesPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 30.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.borderLight.withValues(alpha: 0.1),
                AppColors.borderLight.withValues(alpha: 0.4),
                AppColors.borderLight.withValues(alpha: 0.1),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                  slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Column(
        children: [
          Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26.r),
            ),
          ),
          16.verticalSpace,
          Container(
            height: 400.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1.0), 0.0, 0.0);
  }
}
