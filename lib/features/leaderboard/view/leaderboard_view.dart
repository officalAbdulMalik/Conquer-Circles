import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_participant_tile.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_podium_card.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_scope_switcher.dart';
import 'package:test_steps/features/profile/view/profile_view.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/widgets/shared/dashboard_screen_header.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  int _selectedScope = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
              children: [
                DashboardScreenHeader(
                  title: 'Hi, Aqib Javid',
                  energy: 69,
                  onNotificationsTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  onProfileTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileView()),
                    );
                  },
                ),
                18.verticalSpace,
                LeaderboardScopeSwitcher(
                  selectedIndex: _selectedScope,
                  onChanged: (index) => setState(() => _selectedScope = index),
                ),
                12.verticalSpace,
                const LeaderboardPodiumCard(participants: _participants),
                12.verticalSpace,
                ..._participants
                    .skip(3)
                    .map(
                      (participant) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: LeaderboardParticipantTile(
                          participant: participant,
                        ),
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

const _participants = [
  LeaderboardParticipant(
    name: 'Aqib Javid',
    rank: 1,
    score: 950,
    avatarAsset: 'assets/images/profile.png',
    medal: '🥇',
  ),
  LeaderboardParticipant(
    name: 'Sarah Ahmed',
    rank: 2,
    score: 901,
    avatarEmoji: '👩🏼',
    medal: '🥈',
  ),
  LeaderboardParticipant(
    name: 'Micheal Waliam',
    rank: 3,
    score: 879,
    avatarEmoji: '🧔🏽',
    medal: '🥉',
    isCurrentUser: true,
  ),
  LeaderboardParticipant(
    name: 'Asim Kamal',
    rank: 4,
    score: 843,
    avatarAsset: 'assets/images/profile.png',
  ),
  LeaderboardParticipant(
    name: 'Guy Hawkins',
    rank: 5,
    score: 779,
    avatarEmoji: '🧔🏾',
  ),
  LeaderboardParticipant(
    name: 'Dianne Russell',
    rank: 6,
    score: 712,
    avatarEmoji: '👨🏾',
  ),
  LeaderboardParticipant(
    name: 'Devon Lane',
    rank: 7,
    score: 645,
    avatarEmoji: '👨🏼',
  ),
];
