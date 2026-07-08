import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/view/edit_profile_view.dart';
import 'package:test_steps/features/settings/view/faqs_screen.dart';
import 'package:test_steps/features/settings/view/location_settings_screen.dart';
import 'package:test_steps/features/settings/widgets/delete_account_dialog.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

Future<void> showSettingsBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const SettingsBottomSheet(),
  );
}

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final notificationsEnabled =
        profileState.profileData?.profile.notificationsEnabled ?? true;
    final locationAllowed = ref.watch(mapProvider).permissionGranted;

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          children: [
            10.verticalSpace,
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 10.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'SETTING',
                      style: AppTextStyles.montserrat(
                        size: 16,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(
                        Icons.close_rounded,
                        size: 26.r,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 28.h),
                children: [
                  const _SectionTitle('Profile'),
                  10.verticalSpace,
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.manage_accounts_outlined,
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
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Faqs',
                        subtitle: 'Frequently asked questions',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FaqsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  18.verticalSpace,
                  const _SectionTitle('Preference'),
                  10.verticalSpace,
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification',
                        subtitle: 'We’ll keep you updated on progress',
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
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'Location Service',
                        subtitle: locationAllowed ? 'Allowed' : 'Not allowed',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LocationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Privacy policy',
                        onTap: () => _showInfoDialog(
                          context,
                          title: 'Privacy Policy',
                          message:
                              'Your activity and location data are used to calculate fitness progress and territory features. Account controls will remain available from this settings page.',
                        ),
                      ),
                    ],
                  ),
                  18.verticalSpace,
                  const _SectionTitle('Account'),
                  10.verticalSpace,
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete',
                        subtitle: 'All your data will be permanently removed',
                        onTap: () => showDeleteAccountFlow(context, ref),
                      ),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        subtitle: 'Logout of app',
                        onTap: () => _confirmSignOut(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.montserrat(size: 16, weight: FontWeight.w500),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              children[index],
              if (index != children.length - 1)
                Divider(
                  height: 1.h,
                  thickness: 1.h,
                  color: AppColors.borderColor,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Icon(icon, size: 24.r, color: AppColors.textPrimary),
            ),
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.montserrat(
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.montserrat(
                      size: 12,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[8.horizontalSpace, trailing!],
          ],
        ),
      ),
    );
  }
}

Future<void> _showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
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
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await ref.read(profileProvider.notifier).logout();
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
