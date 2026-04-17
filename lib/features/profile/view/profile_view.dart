import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/view/edit_profile_view.dart';
import 'package:test_steps/features/steps/widgets/steps_dashboard_sections.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/widgets/shared/app_button.dart';
import 'package:test_steps/models/profile_data_model.dart';
import '../widgets/profile_menu_tile.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _isWeekly = true;

  final weekData = [0.55, 0.75, 0.4, 0.85, 0.95, 0.65, 0.7];
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return userProfile.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (profileData) {
        if (profileData == null) {
          return const Scaffold(
            body: Center(child: Text('No profile data found')),
          );
        }

        final profile = profileData.profile;
        final stats = profileData.stats;

        final username = profile.username;
        final totalSteps = stats.totalSteps;
        final totalCalories = stats.totalCalories;
        final totalDistance =
            stats.totalDistanceKm *
            1000; // Convert km to meters for display logic
        final currentStreak = profile.dailyStreak;
        final level = profile.level;
        final avatarUrl = profile.avatarUrl;
        final leagueRank = 4; // Placeholder for now
        final joinedAt = profile.createdAt?.toIso8601String() ?? '';
        final notificationsEnabled = profile.notificationsEnabled;

        // Prepare analytics data
        final currentAnalytics = _isWeekly
            ? profileData.analytics.weekly
            : profileData.analytics.monthly;
        final displayCount = _isWeekly ? 7 : currentAnalytics.length;

        // Take last N days if available
        final displayData = currentAnalytics.length >= displayCount
            ? currentAnalytics.sublist(currentAnalytics.length - displayCount)
            : currentAnalytics;

        final maxSteps = displayData.isEmpty
            ? 10000
            : displayData.map((e) => e.steps).reduce((a, b) => a > b ? a : b);
        final normalizedMax = maxSteps < 5000 ? 5000.0 : maxSteps.toDouble();

        print('notifiction is enabled $notificationsEnabled');

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7B6FD4),
                        Color(0xFF9B8FE8),
                        Color(0xFFB8A8F0),
                        Color(0xFF7EC8D8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28, top: 20),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8E4FF),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child:
                                      avatarUrl != null && avatarUrl.isNotEmpty
                                      ? Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.person_outline_rounded,
                                                size: 44,
                                                color: Color(0xFF8B80CC),
                                              ),
                                        )
                                      : const Icon(
                                          Icons.person_outline_rounded,
                                          size: 44,
                                          color: Color(0xFF8B80CC),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    final saved = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const EditProfileView(),
                                          ),
                                        );
                                    if (saved == true) {
                                      ref.invalidate(userProfileProvider);
                                    }
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          12.verticalSpace,
                          Text(
                            username,
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          4.verticalSpace,
                          Text(
                            '@${username.toLowerCase()} · Joined ${_formatDate(joinedAt)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          12.verticalSpace,
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🏅', style: AppTextStyles.bodyMedium),
                                6.horizontalSpace,
                                Text(
                                  'Level $level · Elite Runner',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ProfileProgressCard(
                        userName: username,
                        xpCurrent: profile.xp,
                        xpGoal: 1000, // Placeholder
                        xpProgress: (profile.xp % 1000) / 1000,
                        pulseValue: (profile.xp % 1000) / 1000,
                        level: level,
                      ),
                      20.verticalSpace,
                      Row(
                        children: [
                          _buildStatCard(
                            '🔨',
                            _formatNumber(totalSteps),
                            'Total Steps',
                            const Color(0xFFF0F0F0),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            '🔥',
                            _formatNumber(totalCalories),
                            'Calories',
                            const Color(0xFFFFF0F0),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            '🗺️',
                            '${((totalDistance as num?)?.toInt() ?? 0) ~/ 1000} km',
                            'Distance',
                            const Color(0xFFEFF8FF),
                          ),
                        ],
                      ),
                      12.verticalSpace,
                      Row(
                        children: [
                          // Current Streak
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text(
                                        '🔥',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Current Streak',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF888888),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$currentStreak',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFE05A5A),
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        child: Text(
                                          'days in a row 🔥',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Dot progress
                                  Row(
                                    children: List.generate(7, (i) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 5),
                                        width: i < currentStreak % 7 ? 22 : 14,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: i < currentStreak % 7
                                              ? const Color(0xFFE05A5A)
                                              : const Color(0xFFEEEEEE),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          12.verticalSpace,
                          // League Rank
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text(
                                        '🏆',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'League Rank',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF888888),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '#$leagueRank',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFD4900A),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Gold Division',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF555555),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0C0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '🥇',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Top 5% this week',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFAA7700),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      16.verticalSpace,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Achievements',
                                  style: AppTextStyles.heading3,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline,
                                      size: 14,
                                      color: Color(0xFF999999),
                                    ),
                                    4.horizontalSpace,
                                    Text(
                                      '${profileData.badges.length} / 30', // Placeholder total
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            16.verticalSpace,
                            GridView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 5,
                                    mainAxisSpacing: 5,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: profileData.badges.length,
                              itemBuilder: (context, i) {
                                final a = profileData.badges[i];
                                final done = a.isUnlocked;
                                return Column(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: done
                                                ? _achievementColor(
                                                    i,
                                                  ).withOpacity(0.15)
                                                : const Color(0xFFF0F0F0),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              a.icon,
                                              style: const TextStyle(
                                                fontSize: 26,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (done)
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF4CAF50),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      a.title,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: done
                                            ? const Color(0xFF333333)
                                            : const Color(0xFFBBBBBB),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      16.verticalSpace,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Activity', style: AppTextStyles.heading3),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _isWeekly = true),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _isWeekly
                                                ? const Color(0xFF7B6FD4)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Weekly',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: _isWeekly
                                                      ? Colors.white
                                                      : const Color(0xFF888888),
                                                ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _isWeekly = false),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: !_isWeekly
                                                ? const Color(0xFF7B6FD4)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Monthly',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: !_isWeekly
                                                      ? Colors.white
                                                      : const Color(0xFF888888),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 120,
                              child: displayData.isEmpty
                                  ? const Center(
                                      child: Text('No activity data yet'),
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        displayData.length,
                                        (i) {
                                          final point = displayData[i];
                                          final heightFactor =
                                              point.steps / normalizedMax;
                                          final date = DateTime.tryParse(
                                            point.date,
                                          );
                                          final label = _isWeekly
                                              ? (date != null
                                                    ? _getDayName(date.weekday)
                                                    : point.date)
                                              : (date != null
                                                    ? date.day.toString()
                                                    : '');

                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                width: _isWeekly
                                                    ? 30
                                                    : (300 / displayData.length)
                                                          .clamp(4, 20),
                                                height: (heightFactor * 90)
                                                    .clamp(5, 90),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      const Color(
                                                        0xFF7B6FD4,
                                                      ).withOpacity(0.9),
                                                      const Color(
                                                        0xFF7B6FD4,
                                                      ).withOpacity(0.3),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              8.verticalSpace,
                                              Text(
                                                label,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      fontSize: _isWeekly
                                                          ? 12.sp
                                                          : 8.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                            ),
                            12.verticalSpace,
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7B6FD4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Avg: ${_calculateAvg(displayData)} steps/day this period',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      16.verticalSpace,
                      _buildSettingsSection(notificationsEnabled),
                      16.verticalSpace,
                      AppButton(
                        label: 'Edit Profile',
                        onPressed: () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileView(),
                            ),
                          );
                          if (saved == true) {
                            ref.invalidate(userProfileProvider);
                          }
                        },
                        isFullWidth: true,
                      ),
                      12.verticalSpace,
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFE05A5A),
                          size: 18,
                        ),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Color(0xFFE05A5A),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      32.verticalSpace,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String emoji,
    String value,
    String label,
    Color bgColor,
  ) {
    final isCalories = label == 'Calories';
    final isDistance = label == 'Distance';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
            ),
            8.verticalSpace,
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isCalories
                    ? const Color(0xFFE05A5A)
                    : isDistance
                    ? const Color(0xFF4A90E2)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            2.verticalSpace,
            Text(label, style: AppTextStyles.bodySmall.copyWith()),
          ],
        ),
      ),
    );
  }

  Color _achievementColor(int i) {
    const colors = [
      Color(0xFFFFA500),
      Color(0xFFE05A5A),
      Color(0xFF7B6FD4),
      Color(0xFF4A90E2),
      Color(0xFF888888),
      Color(0xFF888888),
    ];
    return colors[i];
  }

  String _formatNumber(dynamic value) {
    final number = (value as num?)?.toInt() ?? 0;
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _calculateAvg(List<ChartPoint> data) {
    if (data.isEmpty) return '0';
    final sum = data.fold(0, (prev, element) => prev + element.steps);
    return _formatNumber(sum / data.length);
  }

  // ─── TILE SECTIONS ───────────────────────────────────────────────────────
  Widget _buildSettingsSection(bool notificationsEnabled) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text('Account & Settings', style: AppTextStyles.heading3),
          ),
          12.verticalSpace,
          ProfileMenuTile(
            icon: Icons.notifications_outlined,
            iconBgColor: const Color(0xFFF0F4FF),
            iconColor: const Color(0xFF5B4FE8),
            title: 'Notifications',
            subtitle: 'Daily reminders & alerts',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (val) {
                ref.read(profileProvider.notifier).toggleNotifications(val);
              },
              activeColor: const Color(0xFF5B4FE8),
            ),
          ),
          ProfileMenuTile(
            icon: Icons.security_outlined,
            iconBgColor: const Color(0xFFF5F5F5),
            iconColor: const Color(0xFF555555),
            title: 'Privacy',
            subtitle: 'Control your data',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.straighten_outlined,
            iconBgColor: const Color(0xFFF5FFF0),
            iconColor: const Color(0xFF4CAF50),
            title: 'Units',
            subtitle: 'Metric / Imperial',
            onTap: () {},
          ),
          20.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text('Connected Devices', style: AppTextStyles.heading3),
          ),
          12.verticalSpace,
          ProfileMenuTile(
            icon: Icons.apple,
            iconBgColor: const Color(0xFFFFEEEE),
            iconColor: const Color(0xFFE05A5A),
            title: 'Apple Health',
            subtitle: 'Synced 2m ago',
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                  6.horizontalSpace,
                  Text(
                    'Connected',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.fitness_center_rounded,
            iconBgColor: const Color(0xFFF0FFF0),
            iconColor: const Color(0xFF4CAF50),
            title: 'Google Fit',
            subtitle: 'Not connected',
            trailing: Text(
              'Connect',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
