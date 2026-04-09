import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/seasons/view/season_recap_view.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/social/widgets/chat_preview.dart';
import 'package:test_steps/features/social/widgets/circle_card.dart';
import 'package:test_steps/features/social/widgets/header_widget.dart';
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
                SizedBox(height: 10.h),

                /// HEADER
                const CirclesHeader(),

                SizedBox(height: 20.h),

                /// SEASON CARD
                SeasonCountdownCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SeasonRecapView(
                          seasonId: 4,
                          seasonName: '4',
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                /// CIRCLE CARD
                const GuildCard(),

                SizedBox(height: 16.h),

                /// LEADERBOARD
                const LeaderboardCard(),

                SizedBox(height: 16.h),

                /// SPECIAL RANKINGS
                const SpecialRankingsSection(),

                SizedBox(height: 16.h),
                RaidAlertsCard(),
                SizedBox(height: 16.h),

                /// CHAT PREVIEW
                CircleChatCard(),

                SizedBox(height: 20.h),

                /// JOIN BUTTON
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Browse & Join Other Circles',
                    variant: AppButtonVariant.outlined,
                    backgroundColor: AppColors.brandPurple,
                    borderColor: AppColors.brandPurple.withValues(alpha: 0.3),
                    textStyle: AppTextStyles.poppins(
                      size: 14,
                      color: AppColors.brandPurple,
                      weight: FontWeight.w600,
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
