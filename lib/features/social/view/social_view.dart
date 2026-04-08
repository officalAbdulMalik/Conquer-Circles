import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/social/widgets/chat_preview.dart';
import 'package:test_steps/features/social/widgets/circle_card.dart';
import 'package:test_steps/features/social/widgets/header_widget.dart';
import 'package:test_steps/features/social/widgets/leader_board.dart';
import 'package:test_steps/features/social/widgets/ranking.dart';
import 'package:test_steps/features/social/widgets/red_alerts.dart';
import 'package:test_steps/features/social/widgets/session_widget.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFEFF4FF)],
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
                const SeasonCountdownCard(),

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
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllCirclesPage(),
                      ),
                    );
                    // Handle browse circles action
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFF675FAA).withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Browse & Join Other Circles",
                        style: TextStyle(
                          color: const Color(0xFF675FAA),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
