import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/widgets/shared/custom_app_dialog.dart';

/// Shared account-deletion flow used by both the settings bottom sheet and the
/// Accounts settings screen.
///
/// Shows the confirmation dialog, and on confirm requests a soft deletion
/// (7-day grace period) via [ProfileNotifier.deleteAccount]. On success the
/// session is cleared and the app routes back to the auth gate, so the sheet /
/// screen is torn down automatically. On failure the user sees an error and
/// stays signed in.
Future<void> showDeleteAccountFlow(BuildContext context, WidgetRef ref) async {
  final confirmed = await showCustomAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    dialog: const DeleteAccountDialog(),
  );

  if (confirmed != true || !context.mounted) return;

  // Blocking progress while the request is in flight.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await ref.read(profileProvider.notifier).deleteAccount();
    // Success: logout() clears the session, the app rebuilds to the auth gate,
    // and this route (with its progress dialog) is disposed. Nothing to do.
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not delete your account. Please try again.'),
      ),
    );
  }
}

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

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
                  'This permanently deletes your account and all your data right away. This action can’t be undone.',
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
