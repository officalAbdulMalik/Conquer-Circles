import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/view/edit_profile_view.dart';
import 'package:test_steps/features/settings/view/faqs_screen.dart';
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/custom_app_dialog.dart';

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
                        onTap: () async {
                          await ref
                              .read(mapProvider.notifier)
                              .initialize(forceRequest: true);
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
                        onTap: () => _showDeleteAccountDialog(context),
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

Future<void> _showDeleteAccountDialog(BuildContext context) async {
  final requested = await showCustomAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    dialog: const _DeleteAccountDialog(),
  );

  if (requested != true || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Delete account request submitted.')),
  );
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 24.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.14),
              blurRadius: 26.r,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -8.h,
              right: -8.w,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                  size: 28.sp,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B7F), Color(0xFFD72F46)],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD72F46).withValues(alpha: 0.22),
                        blurRadius: 14.r,
                        offset: Offset(0, 7.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    color: AppColors.surface,
                    size: 34.sp,
                  ),
                ),
                18.verticalSpace,
                Text(
                  'Delete Your Account',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 21.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                14.verticalSpace,
                Text(
                  'This will remove your account permanently, you’re request will be processed within 7 days. We’ll notify you once it’s complete',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    height: 1.42,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                  ),
                ),
                24.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: _DeleteDialogButton(
                        label: 'Cancel',
                        foregroundColor: AppColors.blueColor,
                        borderColor: AppColors.blueColor,
                        backgroundColor: AppColors.surface,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    14.horizontalSpace,
                    Expanded(
                      child: _DeleteDialogButton(
                        label: 'Delete Account',
                        foregroundColor: AppColors.surface,
                        backgroundColor: const Color(0xFFF5484E),
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  const _DeleteDialogButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51.h,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25.5.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25.5.r),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.5.r),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: 1.6.w),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: foregroundColor,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
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
