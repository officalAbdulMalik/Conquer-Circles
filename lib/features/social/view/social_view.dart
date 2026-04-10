import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/seasons/view/season_recap_view.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/social/widgets/chat_preview.dart';
import 'package:test_steps/features/social/widgets/circle_card.dart';
import 'package:test_steps/features/social/widgets/leader_board.dart';
import 'package:test_steps/features/social/widgets/ranking.dart';
import 'package:test_steps/features/social/widgets/red_alerts.dart';
import 'package:test_steps/features/social/widgets/session_widget.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                SizedBox(height: MediaQuery.of(context).padding.top + 20.h),

                SeasonCountdownCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SeasonRecapView(seasonId: 4, seasonName: '4'),
                      ),
                    );
                  },
                ),
                16.verticalSpace,

                /// CIRCLE CARD
                const GuildCard(),

                16.verticalSpace,

                /// LEADERBOARD
                const LeaderboardCard(),

                16.verticalSpace,

                /// SPECIAL RANKINGS
                const SpecialRankingsSection(),

                16.verticalSpace,
                RaidAlertsCard(),
                16.verticalSpace,

                /// CHAT PREVIEW
                CircleChatCard(),

                20.verticalSpace,

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
            ),
          ),
        ),
      ),
    );
  }
}
