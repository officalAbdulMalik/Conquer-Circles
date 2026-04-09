import 'package:flutter/material.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/widgets/notifications/notifications_content_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(child: NotificationsContentTile()),
    );
  }
}
