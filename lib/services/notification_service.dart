import 'dart:async';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) print('[FCM] Background: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  static final _notifController =
      StreamController<NotificationEvent>.broadcast();
  static final _tapController =
      StreamController<NotificationTapEvent>.broadcast();

  static Stream<NotificationEvent> get notificationStream =>
      _notifController.stream;
  static Stream<NotificationTapEvent> get tapStream => _tapController.stream;

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  // ---------------------------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      if (kDebugMode) print('[FCM] Permission denied');
      return;
    }
    if (kDebugMode) print('[FCM] Permission granted');

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    final token = await _messaging.getToken();
    print('FCM TOKEN: $token');
    if (token != null) await _saveTokenToSupabase(token);
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

    _setupMessageHandlers();

    if (kDebugMode) print('[FCM] Ready');
  }

  // ---------------------------------------------------------------------------
  // TOKEN
  // ---------------------------------------------------------------------------

  static Future<void> _saveTokenToSupabase(String token) async {
    final supabase = SupabaseService();
    await supabase.saveFcmToken(token);
    if (kDebugMode) print('[FCM] Token saved');
  }

  // ---------------------------------------------------------------------------
  // MESSAGE HANDLERS (your original structure kept, extended)
  // ---------------------------------------------------------------------------

  static void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final type = message.data['type'] as String? ?? 'general';

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Color(_colorForType(type)),
              styleInformation: BigTextStyleInformation(
                notification.body ?? '',
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: type,
        );
      }

      _notifController.add(
        NotificationEvent(
          type: type,
          title: notification?.title ?? '',
          body: notification?.body ?? '',
          data: message.data,
        ),
      );
    });

    // When app is opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('[FCM] Opened from background: ${message.data}');
      _handleTap(message.data);
    });

    // When app was terminated
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        if (kDebugMode) print('[FCM] Opened from terminated: ${message.data}');
        _handleTap(message.data);
      }
    });
  }

  static void _onLocalNotifTap(NotificationResponse response) {
    _tapController.add(
      NotificationTapEvent(type: response.payload ?? 'general', data: {}),
    );
  }

  static void _handleTap(Map<String, dynamic> data) {
    _tapController.add(
      NotificationTapEvent(
        type: data['type'] as String? ?? 'general',
        data: data,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IN-APP NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Call from: NotificationsScreen on init + pull-to-refresh
  static Future<List<Map<String, dynamic>>> getMyNotifications({
    int from = 0,
    int to = 29,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final res = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) print('[Notifications] getMyNotifications: $e');
      return [];
    }
  }

  /// Call from: BottomNavigationBar badge
  static Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final res = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return (res as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Call from: NotificationsScreen on item tap
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      if (kDebugMode) print('[Notifications] markAsRead: $e');
    }
  }

  /// Call from: NotificationsScreen "Mark all read" button
  static Future<void> markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      if (kDebugMode) print('[Notifications] markAllRead: $e');
    }
  }

  /// Real-time stream — call from: NotificationsScreen + nav badge
  static Stream<List<Map<String, dynamic>>> notificationsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(30)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ---------------------------------------------------------------------------
  // FLUTTER-TRIGGERED NOTIFICATIONS
  // DB triggers handle: attacks, captures, cluster, energy full, invites.
  // These handle: location-aware + context-aware triggers.
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // 1. ONBOARDING
  // ---------------------------------------------------------------------------

  // static Future<void> _sendDirectNotification({
  //   required String userId,
  //   required String type,
  //   required String title,
  //   required String message,
  //   Map<String, dynamic>? data,
  // }) async {
  //   try {
  //     // 1. Insert into DB for in-app notifications screen/stream
  //     await _client.from('notifications').insert({
  //       'user_id': userId,
  //       'type': type,
  //       'title': title,
  //       'message': message,
  //     });

  //     // 2. Send direct push notification via FCM
  //     await SupabaseService().sendNotification(
  //       userId,
  //       title,
  //       message,
  //       type: type,
  //       data: data,
  //     );
  //   } catch (e) {
  //     if (kDebugMode) print('[Notifications] _sendDirectNotification: $e');
  //   }
  // }

  static Future<void> sendWelcomeNotification() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Welcome to Conquer Circles 🗺️',
      'Your territory awaits. Take your first walk and start claiming the streets around you.',
    );
  }

  static Future<void> notifyFirstTerritoryClaim() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'You claimed your first territory!',
      'Nice start. Keep walking to expand your control and build your first cluster.',
    );
  }

  static Future<void> sendJoinCircleReminder() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Play with friends',
      'Create a circle or invite friends to start competing for territory.',
    );
  }

  // ---------------------------------------------------------------------------
  // 2. WALKING & ACTIVITY
  // ---------------------------------------------------------------------------

  static Future<void> sendDailyWalkReminder() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Your territory needs you',
      'Take a quick walk today to strengthen your tiles and earn attack energy.',
    );
  }

  static Future<void> notifyEnergyFull() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Your energy is full',
      'You’ve reached max attack energy. Use it to conquer nearby territory.',
    );
  }

  static Future<void> notifyPowerHourStarted() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Power Hour activated ⚡',
      'Your steps now generate double energy for the next hour.',
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TERRITORY
  // ---------------------------------------------------------------------------

  static Future<void> notifyTerritoryUnderAttack(String ownerId) async {
    await SupabaseService().sendNotification(
      ownerId,
      'Your territory is under attack',
      'A rival is trying to capture one of your tiles. Walk nearby to defend it.',
    );
  }

  static Future<void> notifyTerritoryLost(
    String ownerId,
    String rivalUsername,
  ) async {
    await SupabaseService().sendNotification(
      ownerId,
      'You lost a tile',
      '$rivalUsername captured one of your territories. Walk there to take it back.',
    );
  }

  static Future<void> notifyTerritoryDefended(String ownerId) async {
    await SupabaseService().sendNotification(
      ownerId,
      'Defense successful 🛡️',
      'Your tile resisted an attack. Your territory remains secure.',
    );
  }

  static Future<void> notifyTerritoryStrengthened() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Your territory just got stronger',
      'Walking through your tiles increased their defense energy.',
    );
  }

  // ---------------------------------------------------------------------------
  // 4. RIVAL ACTIVITY
  // ---------------------------------------------------------------------------

  /// Notify owner when rival is near their territory.
  static Future<void> notifyRivalNearby({
    required String ownerUserId,
    required String rivalUsername,
  }) async {
    try {
      await SupabaseService().sendNotification(
        ownerUserId,
        'A rival is nearby',
        '$rivalUsername is walking close to your territory.',
      );
    } catch (e) {
      if (kDebugMode) print('[Notifications] notifyRivalNearby: $e');
    }
  }

  static Future<void> notifyRivalExpansion(
    String userId,
    String rivalUsername,
  ) async {
    await SupabaseService().sendNotification(
      userId,
      'A rival is expanding',
      '$rivalUsername just captured new tiles in your circle.',
    );
  }

  /// Notifies all circle members when rank 1 changes.
  static Future<void> notifyRivalDominating({
    required String circleId,
    required String leaderUserId,
    required String leaderUsername,
  }) async {
    try {
      final members = await _client
          .from('circle_members')
          .select('user_id')
          .eq('circle_id', circleId)
          .neq('user_id', leaderUserId);

      for (final m in members as List) {
        await SupabaseService().sendNotification(
          m['user_id'],
          'Someone is dominating the map',
          '$leaderUsername is leading your circle leaderboard.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[Notifications] notifyRivalDominating: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 5. RAID
  // ---------------------------------------------------------------------------

  /// Notify user of a low-energy tile nearby (< 15 energy).
  static Future<void> notifyRaidOpportunity({
    required String tileId,
    required int tileEnergy,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.rpc(
        'notify_raid_opportunity',
        params: {
          'p_attacker_id': userId,
          'p_tile_id': tileId,
          'p_tile_energy': tileEnergy,
        },
      );
    } catch (e) {
      if (kDebugMode) print('[Notifications] notifyRaidOpportunity: $e');
    }
  }

  static Future<void> notifyRaidVictory(
    String userId,
    String victimUsername,
  ) async {
    await SupabaseService().sendNotification(
      userId,
      'Territory captured 🎉',
      'You successfully conquered a tile from $victimUsername.',
    );
  }

  static Future<void> notifyRaidFailed(String userId) async {
    await SupabaseService().sendNotification(
      userId,
      'Raid failed',
      'That tile was stronger than expected. Walk more and try again.',
    );
  }

  // ---------------------------------------------------------------------------
  // UTILITIES & SCHEDULING
  // ---------------------------------------------------------------------------

  /// End-of-day steps + captures summary.
  static Future<void> sendDailySummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.rpc('send_daily_summary', params: {'p_user_id': userId});
    } catch (e) {
      if (kDebugMode) print('[Notifications] sendDailySummary: $e');
    }
  }

  /// Streak at risk — deduped daily server-side.
  static Future<void> checkStreakReminder({
    required int currentStreak,
    required int todaySteps,
    required int goalSteps,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || currentStreak == 0 || todaySteps >= goalSteps) return;
    try {
      await SupabaseService().sendNotification(
        userId,
        'Don’t break your streak 🔥',
        'A short walk today will keep your walking streak alive.',
      );
    } catch (e) {
      if (kDebugMode) print('[Notifications] checkStreakReminder: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 6. CLUSTERS
  // ---------------------------------------------------------------------------

  static Future<void> notifyClusterCreated() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'You formed a cluster',
      'Connected tiles now give you a defense bonus.',
    );
  }

  static Future<void> notifyClusterBroken(String ownerId) async {
    await SupabaseService().sendNotification(
      ownerId,
      'Cluster broken',
      'A rival captured a tile and broke your territory cluster.',
    );
  }

  // ---------------------------------------------------------------------------
  // 7. CIRCLE SOCIAL
  // ---------------------------------------------------------------------------

  static Future<void> notifyCircleInvite(
    String userId,
    String inviterUsername,
  ) async {
    await SupabaseService().sendNotification(
      userId,
      'You’ve been invited',
      '$inviterUsername invited you to join their circle. Compete for territory.',
    );
  }

  static Future<void> notifyFriendJoinedCircle(
    String userId,
    String friendUsername,
  ) async {
    await SupabaseService().sendNotification(
      userId,
      'A new challenger arrives',
      '$friendUsername joined your circle.',
    );
  }

  static Future<void> notifyFriendStoleTile(
    String userId,
    String friendUsername,
  ) async {
    await SupabaseService().sendNotification(
      userId,
      'Your friend stole your tile',
      '$friendUsername just captured your territory.',
    );
  }

  // ---------------------------------------------------------------------------
  // 8. BADGES
  // ---------------------------------------------------------------------------

  static Future<void> notifyBadgeEarned({
    required String badgeName,
    bool isRare = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      isRare ? 'Legendary achievement' : 'Badge unlocked 🏆',
      isRare
          ? 'You unlocked the rare "$badgeName" badge.'
          : 'You earned the "$badgeName" badge.',
    );
  }

  // ---------------------------------------------------------------------------
  // 9. SEASONAL
  // ---------------------------------------------------------------------------

  static Future<void> notifySeasonStarting() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'New season begins',
      'The map resets today. Start walking and conquer new territory.',
    );
  }

  static Future<void> notifyMidSeasonReminder() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Halfway through the season',
      'You still have time to climb the leaderboard.',
    );
  }

  static Future<void> notifySeasonEndingSoon() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Season ending soon',
      'Only 3 days left. Capture more tiles to secure your rank.',
    );
  }

  static Future<void> notifySeasonResults() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Season results are in',
      'Check your final rank and unlock your rewards.',
    );
  }

  // ---------------------------------------------------------------------------
  // 10. PREMIUM & MONETIZATION
  // ---------------------------------------------------------------------------

  static Future<void> notifyPremiumTrialOffer() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Unlock premium rewards',
      'Upgrade to premium and expand your circles and stats.',
    );
  }

  static Future<void> notifySeasonPassAvailable() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Season Pass unlocked',
      'Unlock exclusive cosmetics and bonus rewards this season.',
    );
  }

  // ---------------------------------------------------------------------------
  // 11. RE-ENGAGEMENT
  // ---------------------------------------------------------------------------

  static Future<void> notifyComeBack() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Your territory misses you',
      'Some of your tiles are weakening. Take a walk to strengthen them.',
    );
  }

  static Future<void> notifyRivalTookArea(String rivalUsername) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService().sendNotification(
      userId,
      'Someone took your street',
      '$rivalUsername captured your territory while you were away.',
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static int _colorForType(String type) {
    switch (type) {
      case 'territory_lost':
      case 'raid_failed':
      case 'cluster_broken':
      case 'rival_took_area':
        return 0xFFF44336;
      case 'territory_under_attack':
      case 'rival_nearby':
        return 0xFFFF5722;
      case 'raid_victory':
      case 'territory_defended':
      case 'territory_strengthened':
      case 'cluster_created':
      case 'first_territory':
      case 'welcome':
        return 0xFF4CAF50;
      case 'energy_full':
      case 'streak_reminder':
      case 'daily_walk_reminder':
      case 'raid_opportunity':
      case 'come_back':
        return 0xFFFF9800;
      case 'circle_invite':
      case 'friend_joined_circle':
      case 'friend_stole_tile':
        return 0xFF9C27B0;
      case 'badge_unlocked':
      case 'rare_badge':
      case 'premium_trial':
      case 'season_pass':
        return 0xFFFFD700;
      case 'power_hour':
      case 'season_starting':
        return 0xFF2196F3;
      default:
        return 0xFF2196F3;
    }
  }

  static void dispose() {
    _notifController.close();
    _tapController.close();
  }

  /// Sends a test notification to the current user to verify RPC/FCM.
  static Future<void> sendTestNotification() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    print('Notification test called');
    try {
      await SupabaseService().sendNotification(
        userId,
        'Test Notification 🧪',
        'If you see this, the notification system is working!',
      );
    } catch (e) {
      print('[Notifications] sendTestNotification: $e');
    }
  }
}

// =============================================================================
// EVENT MODELS
// =============================================================================

class NotificationEvent {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const NotificationEvent({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
  });
}

class NotificationTapEvent {
  final String type;
  final Map<String, dynamic> data;

  const NotificationTapEvent({required this.type, required this.data});

  String get route {
    switch (type) {
      case 'territory_under_attack':
      case 'territory_lost':
      case 'territory_defended':
      case 'territory_strengthened':
      case 'raid_opportunity':
      case 'rival_nearby':
      case 'energy_full':
      case 'cluster_created':
      case 'cluster_broken':
      case 'raid_victory':
      case 'raid_failed':
        return '/map';
      case 'circle_invite':
      case 'friend_joined_circle':
        return '/invites';
      case 'rival_dominating':
      case 'daily_summary':
        return '/leaderboard';
      case 'season_results':
      case 'season_starting':
      case 'mid_season_reminder':
      case 'season_ending_soon':
        return '/recap';
      case 'streak_reminder':
      case 'daily_walk_reminder':
      case 'come_back':
      case 'join_circle_reminder':
      case 'first_territory':
      case 'welcome':
        return '/home';
      default:
        return '/notifications';
    }
  }
}
