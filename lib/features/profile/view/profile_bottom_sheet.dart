import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/auth/goals_selection_screen.dart';
import 'package:test_steps/features/profile/view/edit_profile_view.dart';
import 'package:test_steps/features/profile/widgets/premium_banner_card.dart';
import 'package:test_steps/features/profile/view/referral_code_screen.dart';
import 'package:test_steps/features/profile/widgets/profile_menu_group.dart';
import 'package:test_steps/features/profile/widgets/profile_menu_row.dart';
import 'package:test_steps/features/settings/view/settings_view.dart';
import 'package:test_steps/features/settings/view/location_settings_screen.dart';
import 'package:test_steps/features/subscription/view/plan_purchase_view.dart';
import 'package:test_steps/models/badge_model.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/services/dashboard_service.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

Future<void> showProfileBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const ProfileBottomSheet(),
  );
}

class ProfileBottomSheet extends ConsumerWidget {
  const ProfileBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: const ProfileContent(showCloseButton: true),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final dashboard = ref.watch(dashboardProvider);
    final profile = profileState.profileData?.profile;
    final username = profile?.username ?? dashboard.username;
    final email = SupabaseService().currentUser?.email ?? '';
    final avatarUrl = profile?.avatarUrl;
    final notificationsEnabled =
        profileState.profileData?.profile.notificationsEnabled ?? true;
    final locationAllowed = ref.watch(mapProvider).permissionGranted;

    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: Stack(
        children: [
          AppBackgroundImage(),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
            children: [
              30.verticalSpace,
              _ProfileHeaderSection(
                avatarUrl: avatarUrl,
                username: username,
                email: email,
              ),
              24.verticalSpace,
              PremiumBannerCard(onTap: () {}),
              28.verticalSpace,
              _SectionLabel(label: 'Profile'),
              12.verticalSpace,
              ProfileMenuGroup(
                children: [
                  ProfileMenuRow(
                    icon: 'assets/icons/edit.png',
                    title: 'Edit Profile',
                    subtitle: 'Change and update your profile',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileView(),
                        ),
                      );
                      ref.invalidate(userProfileProvider);
                      await ref
                          .read(profileProvider.notifier)
                          .refreshProfile();
                    },
                  ),
                  ProfileMenuRow(
                    icon: 'assets/icons/goal.png',
                    title: 'Goals',
                    subtitle: 'Adjust your goals',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const GoalsSelectionScreen(isEditMode: true),
                      ),
                    ),
                  ),
                  ProfileMenuRow(
                    icon: 'assets/icons/share.png',
                    title: 'Referral',
                    subtitle: 'Share and manage your referral',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReferralCodeScreen(),
                      ),
                    ),
                  ),
                  ProfileMenuRow(
                    icon: 'assets/icons/card.png',
                    title: 'Plan & Purchase',
                    subtitle: 'Manage subscription',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlanPurchaseView(),
                      ),
                    ),
                  ),
                  ProfileMenuRow(
                    icon: 'assets/icons/setting.png',
                    title: 'Accounts',
                    subtitle: 'System settings',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    ),
                  ),
                ],
              ),
              24.verticalSpace,
              _SectionLabel(label: 'Preference'),
              12.verticalSpace,
              ProfileMenuGroup(
                children: [
                  ProfileMenuRow(
                    icon: 'assets/icons/notification2.png',
                    title: 'Notification',
                    subtitle: "We'll keep you updated on progress",
                    trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: profileState.isLoading
                          ? null
                          : (value) => ref
                                .read(profileProvider.notifier)
                                .toggleNotifications(value),
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF22C9A5),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppColors.textLight,
                      trackOutlineColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  ProfileMenuRow(
                    icon: 'assets/icons/location.png',
                    title: 'Location Service',
                    subtitle: locationAllowed ? 'Allowed' : 'Not allowed',
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LocationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileMenuRow(
                    icon: 'assets/icons/document.png',
                    title: 'Privacy Policy',
                    subtitle: 'Privacy policy',
                    onTap: () {},
                  ),
                ],
              ),
              24.verticalSpace,
              _SectionLabel(label: 'Account'),
              12.verticalSpace,
              ProfileMenuGroup(
                children: [
                  ProfileMenuRow(
                    icon: 'assets/icons/logout.png',
                    title: 'Sign Out',
                    subtitle: 'Logout of app',
                    titleColor: AppColors.error,
                    trailing: const SizedBox.shrink(),
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection({
    required this.avatarUrl,
    required this.username,
    required this.email,
  });

  final String? avatarUrl;
  final String username;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90.r,
          height: 90.r,
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F7),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  )
                : _fallbackAvatar(),
          ),
        ),
        12.verticalSpace,
        Text(
          username,
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(size: 18, weight: FontWeight.w700),
        ),
        4.verticalSpace,
        Text(
          email,
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(
            size: 13,
            color: AppColors.textSecondary,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _fallbackAvatar() {
    return Image.asset(
      'assets/images/profile.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFE5E7EB),
        child: Icon(Icons.person_rounded, size: 48, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.montserrat(
        size: 16.sp,
        weight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'You will need to sign in again to access your account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await ref.read(profileProvider.notifier).logout();
}

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key, required this.showCloseButton});

  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profileData?.profile;
    final badges = profileState.profileData?.badges.isNotEmpty == true
        ? profileState.profileData!.badges
        : dashboard.badges;
    final username = profile?.username ?? dashboard.username;
    final email = SupabaseService().currentUser?.email ?? '';

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'PROFILE',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              _HeaderButton(
                icon: Icons.settings_outlined,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsView())),
              ),
              if (showCloseButton) ...[
                8.horizontalSpace,
                _HeaderButton(
                  icon: Icons.close_rounded,
                  hasBorder: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(profileProvider.notifier).refreshProfile(),
                ref.read(dashboardProvider.notifier).loadDashboard(force: true),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
              children: [
                _ProfileIdentity(
                  username: username,
                  email: email,
                  avatarUrl: profile?.avatarUrl,
                  isLoading:
                      profileState.isLoading &&
                      profileState.profileData == null,
                ),
                20.verticalSpace,
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                  childAspectRatio: 1.82,
                  children: [
                    _StatCard(
                      icon: 'assets/icons/power.png',
                      label: 'Total Distance',
                      value: '${dashboard.distanceKm.toStringAsFixed(2)}km',
                    ),
                    _StatCard(
                      icon: 'assets/icons/walk.png',
                      label: 'Total Duration',
                      value: _formatDuration(dashboard.durationSeconds),
                    ),
                    _StatCard(
                      icon: 'assets/icons/streak.png',
                      label: 'Total Area',
                      value: '${dashboard.totalAreaKm2.toStringAsFixed(1)} km²',
                    ),
                    _StatCard(
                      icon: 'assets/icons/battery.png',
                      label: 'Attack Energy',
                      value: '${dashboard.attackEnergy}',
                    ),
                  ],
                ),
                20.verticalSpace,
                Text(
                  'Badges',
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    weight: FontWeight.w700,
                  ),
                ),
                12.verticalSpace,
                if (profileState.isLoading && badges.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (badges.isEmpty)
                  const _EmptyBadges()
                else
                  GridView.builder(
                    itemCount: badges.take(4).length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 2.45,
                    ),
                    itemBuilder: (_, index) => _BadgeTile(badge: badges[index]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.isLoading,
  });

  final String username;
  final String email;
  final String? avatarUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 130.r,
          height: 130.r,
          padding: EdgeInsets.all(5.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F7),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  )
                : _fallbackAvatar(),
          ),
        ),
        10.verticalSpace,
        Text(
          isLoading ? 'Loading profile...' : username,
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(size: 22, weight: FontWeight.w800),
        ),
        if (email.isNotEmpty) ...[
          6.verticalSpace,
          Text(
            email,
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 14,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _fallbackAvatar() {
    return Image.asset(
      'assets/images/profile.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFE5E7EB),
        child: Icon(Icons.person_rounded, size: 64, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.hasBorder = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: hasBorder ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          border: hasBorder ? Border.all(color: AppColors.borderColor) : null,
        ),
        child: Icon(icon, size: 23.r, color: AppColors.textPrimary),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                icon,
                width: 15.r,
                height: 30.r,
                fit: BoxFit.scaleDown,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.help_outline_rounded,
                  size: 16,

                  // color: AppColors.textSecondary,
                ),
              ),
              7.horizontalSpace,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textNavy,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.montserrat(
              size: 18.sp,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandSecondary,
              shape: BoxShape.circle,
            ),
            child: _BadgeIcon(icon: badge.icon),
          ),
          9.horizontalSpace,
          Expanded(
            child: Text(
              _cleanBadgeTitle(badge.title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 12,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          icon,
          width: 40.r,
          height: 40.r,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    if (icon.startsWith('assets/')) {
      return Image.asset(
        icon,
        width: 23.r,
        height: 23.r,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Text(
      icon,
      maxLines: 1,
      style: TextStyle(fontSize: 20.sp, height: 1),
    );
  }

  Widget _fallback() {
    return Icon(
      Icons.emoji_events_rounded,
      size: 22.r,
      color: AppColors.textPrimary,
    );
  }
}

class _EmptyBadges extends StatelessWidget {
  const _EmptyBadges();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Text(
        'Your earned badges will appear here.',
        textAlign: TextAlign.center,
        style: AppTextStyles.montserrat(
          size: 13,
          color: AppColors.textSecondary,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

String _formatDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours.toString();
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _cleanBadgeTitle(String title) {
  return title.replaceFirst(RegExp(r'^\d+\s+'), '');
}
