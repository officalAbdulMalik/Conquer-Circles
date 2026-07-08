import 'package:flutter/material.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/widgets/notifications/notifications_content_tile.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(),
          const SafeArea(bottom: false, child: NotificationsContentTile()),
        ],
      ),
    );
  }
}
