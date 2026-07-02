import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import 'package:test_steps/models/notification_model.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/widgets/notifications/notification_filter_mode.dart';

/// Immutable UI state for the notifications feed: paged list, loading flags
/// and the active filter. All fetching/pagination/mark-read business logic
/// lives in [NotificationsNotifier] — the UI only renders this state and
/// calls notifier methods.
class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = true,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.filter = NotificationFilterMode.all,
    this.error,
  });

  final List<UserNotification> notifications;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final NotificationFilterMode filter;
  final String? error;

  NotificationsState copyWith({
    List<UserNotification>? notifications,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    NotificationFilterMode? filter,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    fetch();
  }

  static const int _pageSize = 30;
  int _currentIndex = 0;
  bool _fetchInFlight = false;

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentIndex = 0;
      state = state.copyWith(
        hasMore: true,
        isLoading: true,
        clearError: true,
      );
    } else if (_fetchInFlight || state.isFetchingMore || !state.hasMore) {
      return;
    }

    _fetchInFlight = true;
    if (_currentIndex > 0) {
      state = state.copyWith(isFetchingMore: true, clearError: true);
    }

    try {
      final rawList = await NotificationService.getMyNotifications(
        from: _currentIndex,
        to: _currentIndex + _pageSize - 1,
      );
      final newItems = rawList.map(UserNotification.fromJson).toList();
      if (!mounted) return;

      _currentIndex += newItems.length;
      state = state.copyWith(
        notifications: isRefresh
            ? newItems
            : [...state.notifications, ...newItems],
        hasMore: newItems.length == _pageSize,
        isLoading: false,
        isFetchingMore: false,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isFetchingMore: false,
        error: 'Error loading notifications',
      );
    } finally {
      _fetchInFlight = false;
    }
  }

  void setFilter(NotificationFilterMode mode) {
    if (state.filter == mode) return;
    state = state.copyWith(filter: mode);
  }

  /// Marks a single notification read (server + local state).
  Future<void> markAsRead(String notificationId) async {
    await NotificationService.markAsRead(notificationId);
    if (!mounted) return;
    final index = state.notifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index == -1) return;
    final updated = [...state.notifications];
    updated[index] = updated[index].copyWith(isRead: true);
    state = state.copyWith(notifications: updated);
  }

  Future<void> markAllRead() async {
    await NotificationService.markAllRead();
    await fetch(isRefresh: true);
  }
}

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(),
);
