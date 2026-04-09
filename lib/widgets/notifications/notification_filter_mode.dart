import 'package:flutter/material.dart';

import 'package:test_steps/core/theme/app_colors.dart';

/// Visual filter tabs shown on top of the notifications screen.
enum NotificationFilterMode { all, unread, alerts }

extension NotificationFilterModeX on NotificationFilterMode {
  String get label {
    switch (this) {
      case NotificationFilterMode.all:
        return 'All';
      case NotificationFilterMode.unread:
        return 'Unread';
      case NotificationFilterMode.alerts:
        return 'Alerts';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationFilterMode.all:
        return Icons.apps_rounded;
      case NotificationFilterMode.unread:
        return Icons.mark_chat_unread_rounded;
      case NotificationFilterMode.alerts:
        return Icons.warning_amber_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case NotificationFilterMode.all:
        return AppColors.brandPurple;
      case NotificationFilterMode.unread:
        return AppColors.info;
      case NotificationFilterMode.alerts:
        return AppColors.error;
    }
  }
}
