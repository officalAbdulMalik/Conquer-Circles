import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTextStyles.poppins(
            size: 18,
            color: AppColors.textNavy,
            weight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rawList = snapshot.data ?? [];
          if (rawList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = rawList.map((json) => UserNotification.fromJson(json)).toList();

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final UserNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;
    
    return InkWell(
      onTap: () {
        if (!isRead) {
          SupabaseService().markNotificationAsRead(notification.id);
        }
        // Handle navigation based on type if needed
        final event = NotificationTapEvent(type: notification.type, data: {});
        final route = event.route;
        if (route != '/notifications') {
          // In a real app, you'd navigate to the specific route
          // For now, we'll just show the notification as read
        }
      },
      child: Container(
        padding: AppSpacing.symmetric(vertical: 12, horizontal: 8),
        color: isRead ? Colors.transparent : AppColors.brandPrimary.withValues(alpha: 0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(notification.type),
            SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTextStyles.poppins(
                      size: 14,
                      color: AppColors.textNavy,
                      weight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.x4),
                  Text(
                    notification.message,
                    style: AppTextStyles.poppins(
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.x4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notification.createdAt),
                    style: AppTextStyles.poppins(
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'welcome':
      case 'first_territory':
        icon = Icons.emoji_events_outlined;
        color = AppColors.warning;
        break;
      case 'territory_under_attack':
      case 'territory_lost':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case 'raid_victory':
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        break;
      case 'badge_unlocked':
      case 'rare_badge':
        icon = Icons.workspace_premium_outlined;
        color = AppColors.gold;
        break;
      case 'circle_invite':
        icon = Icons.group_add_outlined;
        color = AppColors.info;
        break;
      case 'streak_reminder':
        icon = Icons.local_fire_department_outlined;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = AppColors.brandPrimary;
    }

    return Container(
      padding: AppSpacing.cardAll(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20.sp),
    );
  }
}
