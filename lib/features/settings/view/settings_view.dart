import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/features/auth/update_password_screen.dart';
import 'package:test_steps/features/profile/widgets/profile_menu_row.dart';
import 'package:test_steps/features/settings/view/faqs_screen.dart';
import 'package:test_steps/features/settings/widgets/delete_account_dialog.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_screen_header.dart';
import 'package:test_steps/features/settings/view/energy_usage_screen.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(

        children: [
          AppBackgroundImage(height: 250.h, color: Colors.white.withValues(alpha: 0.72),
          ),
          Padding(
            padding:  EdgeInsets.fromLTRB(16.sp, 16.sp, 16.sp, 24.sp),
            child: SafeArea(
              child: Column(
                children: [
                  const AppScreenHeader(title: 'Accounts'),
                  20.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: AppBorders.raised(),
                    ),
                    child: Column(
                      children: [
                        ProfileMenuRow(
                          icon: 'assets/icons/google.png',
                          title: 'Connected Account',
                          subtitle: 'Social login',
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileMenuRow(
                          icon: 'assets/icons/circle.png',
                          title: 'Energy Usage',
                          subtitle: 'History of attach energy',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EnergyUsageScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileMenuRow(
                          icon: 'assets/icons/key.png',
                          title: 'Change Password',
                          subtitle: 'Manage your password',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UpdatePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileMenuRow(
                          icon: 'assets/icons/question_circle.png',
                          title: 'Faqs',
                          subtitle: 'Frequently ask questions',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FaqsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileMenuRow(
                          icon: 'assets/icons/trash.png',
                          title: 'Delete',
                          subtitle: 'All your data will be permanently removed',
                          onTap: () => showDeleteAccountFlow(context, ref),
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
    );
  }
}

