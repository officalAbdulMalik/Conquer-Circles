import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/models/notification_model.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/widgets/notifications/notification_activity_tile.dart';
import 'package:test_steps/widgets/notifications/notification_day_header_tile.dart';
import 'package:test_steps/widgets/notifications/notification_filter_mode.dart';
import 'package:test_steps/widgets/notifications/notifications_header_tile.dart';
import 'package:test_steps/widgets/notifications/notifications_summary_section_tile.dart';
import 'package:test_steps/screens/main_navigation.dart';

class NotificationsContentTile extends StatefulWidget {
  const NotificationsContentTile({super.key});

  @override
  State<NotificationsContentTile> createState() =>
      NotificationsContentTileState();
}

class NotificationsContentTileState extends State<NotificationsContentTile> {
  final ScrollController _scrollController = ScrollController();
  NotificationFilterMode selectedFilter = NotificationFilterMode.all;
  
  List<UserNotification> _allNotifications = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentIndex = 0;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMore) {
        _fetchNotifications();
      }
    }
  }

  Future<void> _fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentIndex = 0;
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isFetchingMore || !_hasMore) {
      return;
    }

    if (_currentIndex > 0) {
      setState(() => _isFetchingMore = true);
    }

    try {
      final rawList = await NotificationService.getMyNotifications(
        from: _currentIndex,
        to: _currentIndex + _pageSize - 1,
      );
      
      final List<UserNotification> newItems = rawList
          .map(UserNotification.fromJson)
          .toList();

      setState(() {
        if (isRefresh) {
          _allNotifications = newItems;
        } else {
          _allNotifications.addAll(newItems);
        }
        
        _hasMore = newItems.length == _pageSize;
        _currentIndex += newItems.length;
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
      _showMessage('Error loading notifications');
    }
  }

  void onFilterChanged(NotificationFilterMode mode) {
    if (selectedFilter == mode) {
      return;
    }
    setState(() {
      selectedFilter = mode;
    });
  }

  Future<void> _handleNotificationTap(UserNotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
      setState(() {
        final index = _allNotifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
        }
      });
    }

    await HapticFeedback.selectionClick();
    if (!mounted) {
      return;
    }

    final NotificationTapEvent event = NotificationTapEvent(
      type: notification.type,
      data: <String, dynamic>{'notification_id': notification.id},
    );
    final int? tabIndex = NotificationRouteIndexResolver.indexFor(event.route);

    if (tabIndex == null) {
      _showMessage('Opened notification details');
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: tabIndex)),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _handleNotificationLongPress(
    UserNotification notification,
  ) async {
    if (notification.isRead) {
      _showMessage('Notification is already read');
      return;
    }
    await NotificationService.markAsRead(notification.id);
    
    setState(() {
      final index = _allNotifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
      }
    });

    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    _showMessage('Marked as read');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                NotificationQuickActionTile(
                  icon: Icons.apps_rounded,
                  title: 'Show all notifications',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onFilterChanged(NotificationFilterMode.all);
                  },
                ),
                NotificationQuickActionTile(
                  icon: Icons.mark_chat_unread_rounded,
                  title: 'Show unread only',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onFilterChanged(NotificationFilterMode.unread);
                  },
                ),
                NotificationQuickActionTile(
                  icon: Icons.warning_amber_rounded,
                  title: 'Show alerts',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onFilterChanged(NotificationFilterMode.alerts);
                  },
                ),
                NotificationQuickActionTile(
                  icon: Icons.done_all_rounded,
                  title: 'Mark all as read',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await NotificationService.markAllRead();
                    await _fetchNotifications(isRefresh: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFirstCategoryNotification(
    Set<String> categoryTypes,
    List<UserNotification> allNotifications,
    String categoryLabel,
  ) {
    UserNotification? firstMatch;
    for (final UserNotification item in allNotifications) {
      if (categoryTypes.contains(item.type)) {
        firstMatch = item;
        break;
      }
    }

    if (firstMatch == null) {
      _showMessage('No $categoryLabel notifications yet');
      return;
    }
    _handleNotificationTap(firstMatch);
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount = _allNotifications
        .where((n) => !n.isRead)
        .length;
    final int totalCount = _allNotifications.length;
    final NotificationCategoryMetrics metrics =
        NotificationCategoryMetrics.from(_allNotifications);
    final Map<NotificationFilterMode, int> filterCounts =
        <NotificationFilterMode, int>{
          NotificationFilterMode.all: totalCount,
          NotificationFilterMode.unread: unreadCount,
          NotificationFilterMode.alerts:
              NotificationFilterResolver.apply(
                NotificationFilterMode.alerts,
                _allNotifications,
              ).length,
        };

    final List<UserNotification> filteredNotifications =
        NotificationFilterResolver.apply(
          selectedFilter,
          _allNotifications,
        );
    final List<NotificationDayGroup> groups =
        NotificationDayGrouping.createGroups(filteredNotifications);

    return Column(
      children: [
        NotificationsHeaderTile(
          unreadCount: unreadCount,
          totalCount: totalCount,
          selectedFilter: selectedFilter,
          filterCounts: filterCounts,
          onFilterChanged: onFilterChanged,
          onMarkAllRead: () async {
            await NotificationService.markAllRead();
            await _fetchNotifications(isRefresh: true);
          },
          onOptionsTap: _openOptionsSheet,
        ),
        Expanded(
          child: _isLoading && totalCount == 0
              ? const NotificationsLoadingTile()
              : totalCount == 0
                  ? const NotificationsStateMessageTile(
                      icon: Icons.notifications_off_outlined,
                      title: 'No notifications found',
                      message:
                          'New updates from your circles will appear here.',
                      iconColor: AppColors.textNavy,
                    )
                  : RefreshIndicator(
                      color: AppColors.brandPrimary,
                      onRefresh: () => _fetchNotifications(isRefresh: true),
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                        children: [
                          NotificationsSummarySectionTile(
                            raidsCount: metrics.raids,
                            awardsCount: metrics.awards,
                            questsCount: metrics.quests,
                            xpEventsCount: metrics.xpEvents,
                            onRaidsTap: () {
                              onFilterChanged(NotificationFilterMode.alerts);
                              _showMessage('Showing alert notifications');
                            },
                            onAwardsTap: () => _openFirstCategoryNotification(
                              NotificationCategoryTypes.awards,
                              _allNotifications,
                              'award',
                            ),
                            onQuestsTap: () => _openFirstCategoryNotification(
                              NotificationCategoryTypes.quests,
                              _allNotifications,
                              'quest',
                            ),
                            onXpEventsTap: () =>
                                _openFirstCategoryNotification(
                                  NotificationCategoryTypes.xpEvents,
                                  _allNotifications,
                                  'XP event',
                                ),
                          ),
                          SizedBox(height: 14.h),
                          if (groups.isEmpty)
                            const NotificationsInlineMessageTile(
                              message:
                                  'No updates in this filter right now. Try another tab.',
                            )
                          else
                            ...groups.map(
                              (NotificationDayGroup group) =>
                                  NotificationDayGroupTile(
                                    group: group,
                                    onNotificationTap: _handleNotificationTap,
                                    onNotificationActionTap:
                                        _handleNotificationTap,
                                    onNotificationLongPress:
                                        _handleNotificationLongPress,
                                  ),
                            ),
                          if (_isFetchingMore)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                          if (!_hasMore && totalCount > 0)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: Center(
                                child: Text(
                                  'No more notifications to show',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
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
}

class NotificationDayGroupTile extends StatelessWidget {
  const NotificationDayGroupTile({
    super.key,
    required this.group,
    required this.onNotificationTap,
    required this.onNotificationActionTap,
    required this.onNotificationLongPress,
  });

  final NotificationDayGroup group;
  final ValueChanged<UserNotification> onNotificationTap;
  final ValueChanged<UserNotification> onNotificationActionTap;
  final ValueChanged<UserNotification> onNotificationLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationDayHeaderTile(
          label: group.label,
          itemCount: group.items.length,
        ),
        ...group.items.map(
          (UserNotification notification) => NotificationActivityTile(
            notification: notification,
            onTap: () => onNotificationTap(notification),
            onActionTap: () => onNotificationActionTap(notification),
            onLongPress: () => onNotificationLongPress(notification),
          ),
        ),
      ],
    );
  }
}

class NotificationsLoadingTile extends StatelessWidget {
  const NotificationsLoadingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.brandPrimary),
    );
  }
}

class NotificationsStateMessageTile extends StatelessWidget {
  const NotificationsStateMessageTile({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52.sp, color: iconColor),
            SizedBox(height: 12.h),
            Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                color: AppColors.textNavy,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsInlineMessageTile extends StatelessWidget {
  const NotificationsInlineMessageTile({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class NotificationQuickActionTile extends StatelessWidget {
  const NotificationQuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, size: 20.sp, color: AppColors.textNavy),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardSubtitle.copyWith(
                    color: AppColors.textNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationDayGroup {
  const NotificationDayGroup({
    required this.date,
    required this.label,
    required this.items,
  });

  final DateTime date;
  final String label;
  final List<UserNotification> items;
}

class NotificationDayGrouping {
  static List<NotificationDayGroup> createGroups(List<UserNotification> list) {
    final Map<DateTime, List<UserNotification>> groups =
        <DateTime, List<UserNotification>>{};

    for (final UserNotification item in list) {
      final DateTime key = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      groups.putIfAbsent(key, () => <UserNotification>[]).add(item);
    }

    final List<DateTime> sortedKeys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final DateTime now = DateTime.now();

    return sortedKeys
        .map(
          (DateTime date) => NotificationDayGroup(
            date: date,
            label: NotificationDayLabelFormatter.labelFor(date, now),
            items: groups[date]!,
          ),
        )
        .toList();
  }
}

class NotificationDayLabelFormatter {
  static String labelFor(DateTime date, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    }

    if (date == yesterday) {
      return 'Yesterday';
    }

    final Duration gap = today.difference(date);
    if (gap.inDays < 7) {
      return DateFormat('EEEE').format(date);
    }

    return DateFormat('MMM d').format(date);
  }
}

class NotificationFilterResolver {
  static List<UserNotification> apply(
    NotificationFilterMode filter,
    List<UserNotification> notifications,
  ) {
    switch (filter) {
      case NotificationFilterMode.all:
        return notifications;

      case NotificationFilterMode.unread:
        return notifications.where((n) => !n.isRead).toList();

      case NotificationFilterMode.alerts:
        return notifications
            .where((n) => NotificationAlertTypes.values.contains(n.type))
            .toList();
    }
  }
}

class NotificationAlertTypes {
  static const Set<String> values = <String>{
    'territory_under_attack',
    'territory_lost',
    'raid_failed',
    'rival_dominating',
    'energy_full',
    'streak_reminder',
    'daily_walk_reminder',
  };
}

class NotificationCategoryMetrics {
  const NotificationCategoryMetrics({
    required this.raids,
    required this.awards,
    required this.quests,
    required this.xpEvents,
  });

  final int raids;
  final int awards;
  final int quests;
  final int xpEvents;

  factory NotificationCategoryMetrics.from(List<UserNotification> items) {
    int raids = 0;
    int awards = 0;
    int quests = 0;
    int xpEvents = 0;

    for (final UserNotification item in items) {
      if (NotificationCategoryTypes.raids.contains(item.type)) {
        raids += 1;
      } else if (NotificationCategoryTypes.awards.contains(item.type)) {
        awards += 1;
      } else if (NotificationCategoryTypes.quests.contains(item.type)) {
        quests += 1;
      } else if (NotificationCategoryTypes.xpEvents.contains(item.type)) {
        xpEvents += 1;
      }
    }

    return NotificationCategoryMetrics(
      raids: raids,
      awards: awards,
      quests: quests,
      xpEvents: xpEvents,
    );
  }
}

class NotificationCategoryTypes {
  static const Set<String> raids = <String>{
    'territory_under_attack',
    'territory_lost',
    'territory_defended',
    'territory_strengthened',
    'raid_opportunity',
    'rival_nearby',
    'raid_victory',
    'raid_failed',
    'rival_dominating',
  };

  static const Set<String> awards = <String>{
    'badge_unlocked',
    'rare_badge',
    'season_results',
    'season_starting',
  };

  static const Set<String> quests = <String>{
    'welcome',
    'first_territory',
    'streak_reminder',
    'daily_walk_reminder',
    'come_back',
    'join_circle_reminder',
  };

  static const Set<String> xpEvents = <String>{
    'energy_full',
    'cluster_created',
    'cluster_broken',
    'daily_summary',
    'mid_season_reminder',
    'season_ending_soon',
  };
}

class NotificationRouteIndexResolver {
  static int? indexFor(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/map':
        return 1;
      case '/invites':
      case '/leaderboard':
        return 2;
      default:
        return null;
    }
  }
}
