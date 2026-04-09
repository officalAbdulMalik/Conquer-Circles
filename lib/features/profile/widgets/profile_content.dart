import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/view/profile_stats_view.dart';
import 'package:test_steps/features/profile/widgets/profile_achievement_tile.dart';
import 'package:test_steps/features/profile/widgets/profile_settings_tile.dart';
import 'package:test_steps/features/profile/widgets/profile_stat_tile.dart';
import 'package:test_steps/screens/notifications_screen.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({
    super.key,
    required this.username,
    required this.handle,
    required this.onEditProfile,
    required this.onLogout,
  });

  final String username;
  final String handle;
  final VoidCallback onEditProfile;
  final Future<void> Function() onLogout;

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool _isWeekly = true;
  bool _isLoggingOut = false;

  final List<_StatData> _stats = const [
    _StatData(
      icon: '👟',
      value: '1.2M',
      label: 'Total Steps',
      gradient: [Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
      iconBackground: AppColors.brandPurple,
    ),
    _StatData(
      icon: '🔥',
      value: '48.3K',
      label: 'Calories',
      gradient: [Color(0xFFFECACA), Color(0xFFFDA4AF)],
      iconBackground: Color(0xFFEF4444),
    ),
    _StatData(
      icon: '🗺️',
      value: '892 km',
      label: 'Distance',
      gradient: [Color(0xFFBFDBFE), Color(0xFF93C5FD)],
      iconBackground: AppColors.info,
    ),
  ];

  final List<_AchievementData> _achievements = const [
    _AchievementData(icon: '🏃', title: '10K Steps', isCompleted: true),
    _AchievementData(icon: '⚔️', title: 'Week Warrior', isCompleted: true),
    _AchievementData(icon: '🥇', title: 'Elite Pace', isCompleted: true),
    _AchievementData(icon: '🔥', title: 'Streak Star', isCompleted: true),
    _AchievementData(icon: '🏔️', title: 'Hill Master', isCompleted: false),
    _AchievementData(icon: '👑', title: 'Legend Rank', isCompleted: false),
  ];

  final List<_BestData> _bests = const [
    _BestData(title: 'Best Day Steps', value: '14,382'),
    _BestData(title: 'Top Streak', value: '21 days'),
    _BestData(title: 'Best Distance', value: '9.7 km'),
  ];

  final List<_SettingData> _settings = const [
    _SettingData(
      icon: Icons.notifications_active_outlined,
      title: 'Notifications',
      subtitle: 'Daily reminders',
    ),
    _SettingData(
      icon: Icons.shield_outlined,
      title: 'Privacy',
      subtitle: 'Control your data',
    ),
    _SettingData(
      icon: Icons.straighten_outlined,
      title: 'Units',
      subtitle: 'Metric / Imperial',
    ),
  ];

  final List<_DeviceData> _devices = const [
    _DeviceData(name: 'Apple Health', status: 'Connected', isConnected: true),
    _DeviceData(name: 'Google Fit', status: 'Connect', isConnected: false),
  ];

  List<double> get _activityValues {
    if (_isWeekly) {
      return const [8200, 9400, 10150, 7600, 11320, 12700, 9080];
    }
    return const [7600, 8100, 9000, 10200, 10800, 9600, 8900];
  }

  double get _xpProgress => 2450 / 3000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Transform.translate(
                offset: Offset(0, -26.h),
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      18.verticalSpace,
                      _buildHighlights(),
                      18.verticalSpace,
                      _buildAchievements(),
                      18.verticalSpace,
                      _buildActivity(),
                      18.verticalSpace,
                      _buildBests(),
                      18.verticalSpace,
                      _buildSettings(),
                      18.verticalSpace,
                      _buildConnectedDevices(),
                      18.verticalSpace,
                      _buildProgressCard(),
                      20.verticalSpace,
                      _buildActions(),
                      28.verticalSpace,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 280.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34.r),
          bottomRight: Radius.circular(34.r),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D5FEA), Color(0xFF53C5F8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42.h,
            right: -32.w,
            child: _blurCircle(size: 156.w, color: const Color(0x66FFFFFF)),
          ),
          Positioned(
            bottom: -46.h,
            left: -28.w,
            child: _blurCircle(size: 138.w, color: const Color(0x4DF7F7FF)),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104.w,
                      height: 104.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x40000000),
                            blurRadius: 22.r,
                            offset: Offset(0, 8.h),
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEDE9FE), Color(0xFFDBEAFE)],
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 52.sp,
                        color: AppColors.brandPurple,
                      ),
                    ),
                    Positioned(
                      right: -2.w,
                      bottom: -2.h,
                      child: Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.brandPurple,
                            width: 1.4.w,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16.sp,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                14.verticalSpace,
                Text(
                  widget.username,
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 27,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                4.verticalSpace,
                Text(
                  widget.handle,
                  style: AppTextStyles.style(
                    fontFamily: 'Inter',
                    size: 13,
                    color: const Color(0xE6FFFFFF),
                  ),
                ),
                10.verticalSpace,
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(color: const Color(0x55FFFFFF)),
                      ),
                      child: Text(
                        'Level 15 · Elite Runner',
                        style: AppTextStyles.style(
                          fontFamily: 'Inter',
                          size: 12,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _blurCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        for (int i = 0; i < _stats.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileStatsView()),
                );
              },
              child: ProfileStatTile(
                icon: _stats[i].icon,
                value: _stats[i].value,
                label: _stats[i].label,
                gradient: _stats[i].gradient,
                iconBackground: _stats[i].iconBackground,
              ),
            ),
          ),
          if (i < _stats.length - 1) 12.horizontalSpace,
        ],
      ],
    );
  }

  Widget _buildHighlights() {
    return Row(
      children: [
        Expanded(
          child: _glassCard(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                8.verticalSpace,
                Text(
                  '12 days',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 30,
                    weight: FontWeight.w700,
                    color: AppColors.brandPurple,
                    height: 1,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'days in a row 🎉',
                  style: AppTextStyles.style(
                    fontFamily: 'Inter',
                    size: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                12.verticalSpace,
                Row(
                  children: List.generate(8, (index) {
                    final active = index < 6;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 7 ? 0 : 4.w),
                        height: 6.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: active
                              ? AppColors.brandPurple
                              : const Color(0xFFE9EAF4),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: _glassCard(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'League Rank',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                8.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#4',
                      style: AppTextStyles.style(
                        fontFamily: 'Poppins',
                        size: 30,
                        weight: FontWeight.w700,
                        color: const Color(0xFFDB2777),
                        height: 1,
                      ),
                    ),
                    6.horizontalSpace,
                    Text(
                      'Gold',
                      style: AppTextStyles.style(
                        fontFamily: 'Inter',
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFFA16207),
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Top 5% this week',
                    style: AppTextStyles.style(
                      fontFamily: 'Inter',
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return _glassCard(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Achievements (4/6)'),
          14.verticalSpace,
          GridView.builder(
            itemCount: _achievements.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final item = _achievements[index];
              return ProfileAchievementTile(
                icon: item.icon,
                title: item.title,
                isCompleted: item.isCompleted,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivity() {
    final values = _activityValues;
    final maxValue = values.reduce(math.max);
    final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileStatsView()));
      },
      child: _glassCard(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Activity',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    size: 20,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildSegmentedToggle(),
              ],
            ),
            16.verticalSpace,
            SizedBox(
              height: 170.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (index) {
                  final value = values[index];
                  final barHeight = ((value / maxValue) * 110).h;
                  final isPeak = value == maxValue;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 24.w,
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isPeak
                                  ? const [
                                      AppColors.brandPurple,
                                      AppColors.brandCyan,
                                    ]
                                  : const [
                                      Color(0xFFC7D2FE),
                                      Color(0xFFE0E7FF),
                                    ],
                            ),
                          ),
                        ),
                        8.verticalSpace,
                        Text(
                          labels[index],
                          style: AppTextStyles.style(
                            fontFamily: 'Inter',
                            size: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            8.verticalSpace,
            Text(
              'Avg: 9,207 steps/day this week',
              style: AppTextStyles.style(
                fontFamily: 'Inter',
                size: 12,
                weight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        children: [
          _toggleButton(
            label: 'Weekly',
            active: _isWeekly,
            onTap: () => setState(() => _isWeekly = true),
          ),
          _toggleButton(
            label: 'Monthly',
            active: !_isWeekly,
            onTap: () => setState(() => _isWeekly = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0x16000000),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.style(
            fontFamily: 'Inter',
            size: 12,
            weight: FontWeight.w600,
            color: active ? AppColors.textPrimary : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildBests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Personal Bests'),
        12.verticalSpace,
        Row(
          children: [
            for (int i = 0; i < _bests.length; i++) ...[
              Expanded(
                child: _glassCard(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bests[i].title,
                        style: AppTextStyles.style(
                          fontFamily: 'Inter',
                          size: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      8.verticalSpace,
                      Text(
                        _bests[i].value,
                        style: AppTextStyles.style(
                          fontFamily: 'Poppins',
                          size: 18,
                          weight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < _bests.length - 1) 12.horizontalSpace,
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Settings'),
        12.verticalSpace,
        _glassCard(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              for (int i = 0; i < _settings.length; i++) ...[
                ProfileSettingsTile(
                  icon: _settings[i].icon,
                  title: _settings[i].title,
                  subtitle: _settings[i].subtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (i < _settings.length - 1)
                  Divider(height: 1.h, color: const Color(0xFFE8EDF7)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Connected Devices'),
        12.verticalSpace,
        _glassCard(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              for (int i = 0; i < _devices.length; i++) ...[
                Row(
                  children: [
                    Icon(
                      _devices[i].name.contains('Apple')
                          ? Icons.favorite_border
                          : Icons.directions_run,
                      color: const Color(0xFF64748B),
                      size: 20.sp,
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: Text(
                        _devices[i].name,
                        style: AppTextStyles.style(
                          fontFamily: 'Poppins',
                          size: 14,
                          weight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _devices[i].isConnected
                            ? const Color(0xFFE8FCEB)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: _devices[i].isConnected
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        _devices[i].status,
                        style: AppTextStyles.style(
                          fontFamily: 'Inter',
                          size: 12,
                          weight: FontWeight.w600,
                          color: _devices[i].isConnected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < _devices.length - 1) 12.verticalSpace,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return _glassCard(
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'XP Progress',
                style: AppTextStyles.style(
                  fontFamily: 'Poppins',
                  size: 20,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '2,450 / 3,000',
                style: AppTextStyles.style(
                  fontFamily: 'Inter',
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.brandPurple,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(999.r),
            child: Container(
              height: 10.h,
              color: const Color(0xFFEDE9FF),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _xpProgress,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.brandPurple, AppColors.brandCyan],
                    ),
                  ),
                ),
              ),
            ),
          ),
          10.verticalSpace,
          Text(
            '82% to Level 16',
            style: AppTextStyles.style(
              fontFamily: 'Inter',
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          8.verticalSpace,
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Unlock “Marathon Master” badge at Level 16',
              style: AppTextStyles.style(
                fontFamily: 'Inter',
                size: 12,
                color: AppColors.brandPurple,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: widget.onEditProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'Edit Profile',
              style: AppTextStyles.style(
                fontFamily: 'Poppins',
                size: 16,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        10.verticalSpace,
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: OutlinedButton(
            onPressed: _isLoggingOut ? null : _showLogoutDialog,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: const Color(0xFFFCA5A5), width: 1.2.w),
              backgroundColor: const Color(0xFFFFF1F2),
              foregroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: _isLoggingOut
                ? SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDC2626),
                    ),
                  )
                : Text(
                    'Log Out',
                    style: AppTextStyles.style(
                      fontFamily: 'Poppins',
                      size: 16,
                      weight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C2B285C),
      builder: (dialogContext) {
        bool isDialogSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x806958CA),
                      blurRadius: 34.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 12.h),
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Container(
                              width: 30.w,
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F3FE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.sp,
                                color: const Color(0xFF8E8CB5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 66.w,
                        height: 66.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x40FCA5A5),
                              blurRadius: 18.r,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 30.sp,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      16.verticalSpace,
                      Text(
                        'Log Out?',
                        style: AppTextStyles.style(
                          fontFamily: 'Poppins',
                          size: 34 / 2,
                          weight: FontWeight.w700,
                          color: const Color(0xFF2E2E35),
                        ),
                      ),
                      10.verticalSpace,
                      Text(
                        'Are you sure you want to log out?\nYou\'ll need to sign in again to\naccess your fitness data.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.style(
                          fontFamily: 'Inter',
                          size: 16 / 1.2,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8D8E96),
                          height: 1.45,
                        ),
                      ),
                      16.verticalSpace,
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E8),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFF8E3B3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 18.sp)),
                            10.horizontalSpace,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Don\'t lose your streak!',
                                    style: AppTextStyles.style(
                                      fontFamily: 'Poppins',
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFFDD6B20),
                                    ),
                                  ),
                                  3.verticalSpace,
                                  Text(
                                    'You have a 12-day streak going. Come back tomorrow!',
                                    style: AppTextStyles.style(
                                      fontFamily: 'Inter',
                                      size: 12.2,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFFC56A1F),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      18.verticalSpace,
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: isDialogSubmitting
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF7A70C6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(
                            'Stay Logged In',
                            style: AppTextStyles.style(
                              fontFamily: 'Poppins',
                              size: 16,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      10.verticalSpace,
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: OutlinedButton(
                          onPressed: isDialogSubmitting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isDialogSubmitting = true;
                                  });
                                  setState(() => _isLoggingOut = true);

                                  try {
                                    await widget.onLogout();
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  } catch (_) {
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Logout failed. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoggingOut = false);
                                    }
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        isDialogSubmitting = false;
                                      });
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFFF8CACA),
                              width: 1.1.w,
                            ),
                            backgroundColor: const Color(0xFFFFF5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: isDialogSubmitting
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFEF4444),
                                  ),
                                )
                              : Text(
                                  'Log Out',
                                  style: AppTextStyles.style(
                                    fontFamily: 'Poppins',
                                    size: 16,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                        ),
                      ),
                      12.verticalSpace,
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7D9E0),
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.style(
        fontFamily: 'Poppins',
        size: 20,
        weight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _glassCard({required EdgeInsets padding, required Widget child}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0x14675FAA), width: 0.7.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F675FAA),
            blurRadius: 24.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
    required this.iconBackground,
  });

  final String icon;
  final String value;
  final String label;
  final List<Color> gradient;
  final Color iconBackground;
}

class _AchievementData {
  const _AchievementData({
    required this.icon,
    required this.title,
    required this.isCompleted,
  });

  final String icon;
  final String title;
  final bool isCompleted;
}

class _BestData {
  const _BestData({required this.title, required this.value});

  final String title;
  final String value;
}

class _SettingData {
  const _SettingData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _DeviceData {
  const _DeviceData({
    required this.name,
    required this.status,
    required this.isConnected,
  });

  final String name;
  final String status;
  final bool isConnected;
}
