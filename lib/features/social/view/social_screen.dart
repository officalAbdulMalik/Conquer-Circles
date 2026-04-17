import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/chat_models.dart';
import 'package:test_steps/features/social/models/raid_models.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/social/view/create_circle_onboarding_view.dart';
import 'package:test_steps/features/social/widgets/chat_preview.dart';
import 'package:test_steps/features/social/widgets/circle_card.dart';
import 'package:test_steps/features/social/widgets/leader_board.dart';
import 'package:test_steps/features/social/widgets/ranking.dart';
import 'package:test_steps/features/social/widgets/red_alerts.dart';
import 'package:test_steps/providers/circle_messages_provider.dart';
import 'package:test_steps/providers/circle_raid_alerts_provider.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

class CirclesScreen extends ConsumerStatefulWidget {
  final String? circleId; // New parameter to accept circle ID
  const CirclesScreen({super.key, this.circleId});

  @override
  ConsumerState<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends ConsumerState<CirclesScreen> {
  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  DateTime _safeParseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.tryParse(raw) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  String _initialFromName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '👤';
    return trimmed[0].toUpperCase();
  }

  List<ChatMessage> _parseRecentMessages(
    List<dynamic> raw,
    String? currentUserId,
  ) {
    final mapped = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        mapped.add(item);
      } else if (item is Map) {
        mapped.add(Map<String, dynamic>.from(item));
      }
    }

    mapped.sort(
      (a, b) => _safeParseDate(
        a['created_at'],
      ).compareTo(_safeParseDate(b['created_at'])),
    );

    return mapped
        .map((row) {
          final senderInfoRaw = row['sender_info'];
          Map<String, dynamic>? senderInfo;
          if (senderInfoRaw is Map<String, dynamic>) {
            senderInfo = senderInfoRaw;
          } else if (senderInfoRaw is Map) {
            senderInfo = Map<String, dynamic>.from(senderInfoRaw);
          }

          final senderName = senderInfo?['username']?.toString() ?? 'Member';
          final isMe = row['user_id']?.toString() == currentUserId;

          return ChatMessage(
            text: row['message']?.toString() ?? '',
            sender: isMe ? MessageSender.me : MessageSender.other,
            timeLabel: _timeAgo(_safeParseDate(row['created_at'])),
            senderName: isMe ? null : senderName,
            avatarEmoji: isMe ? null : _initialFromName(senderName),
          );
        })
        .where((message) => message.text.trim().isNotEmpty)
        .toList();
  }

  RaidStatus _statusFromRow(Map<String, dynamic> row) {
    final statusRaw = (row['status'] ?? row['action'] ?? row['event_type'])
        ?.toString()
        .toLowerCase();

    if (statusRaw == 'active_attack' ||
        statusRaw == 'active' ||
        statusRaw == 'damaged' ||
        statusRaw == 'under_attack') {
      return RaidStatus.activeAttack;
    }
    if (statusRaw == 'repelled' ||
        statusRaw == 'defended' ||
        statusRaw == 'failed' ||
        statusRaw == 'raid_failed') {
      return RaidStatus.repelled;
    }
    if (statusRaw == 'zone_lost' ||
        statusRaw == 'captured' ||
        statusRaw == 'lost' ||
        statusRaw == 'raid_victory' ||
        statusRaw == 'territory_lost') {
      return RaidStatus.zoneLost;
    }

    final captured = row['captured'] == true;
    return captured ? RaidStatus.zoneLost : RaidStatus.activeAttack;
  }

  List<RaidAlert> _parseRaidAlerts(List<dynamic> raw) {
    final mapped = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        mapped.add(item);
      } else if (item is Map) {
        mapped.add(Map<String, dynamic>.from(item));
      }
    }

    mapped.sort(
      (a, b) => _safeParseDate(
        b['created_at'],
      ).compareTo(_safeParseDate(a['created_at'])),
    );

    return mapped.map((row) {
      final status = _statusFromRow(row);
      final attacker =
          row['attacker_name']?.toString() ??
          row['attacker_username']?.toString() ??
          row['attacker']?.toString() ??
          'Rival';
      final target =
          row['target_name']?.toString() ??
          row['territory_name']?.toString() ??
          row['tile_id']?.toString() ??
          'Territory';

      final iconEmoji = switch (status) {
        RaidStatus.activeAttack => AppEmojis.swords,
        RaidStatus.repelled => AppEmojis.shield,
        RaidStatus.zoneLost => AppEmojis.dead,
      };

      return RaidAlert(
        attacker: attacker,
        target: target,
        status: status,
        timeAgo: _timeAgo(_safeParseDate(row['created_at'])),
        iconEmoji: iconEmoji,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // No manual fetch needed, circleDetailsProvider handles it.
  }

  @override
  Widget build(BuildContext context) {
    final String? activeCircleId =
        widget.circleId ??
        ref
            .watch(circlesProvider)
            .circles
            .firstOrNull?['circle_id']
            ?.toString();

    AsyncValue<Map<String, dynamic>?>? circleDetailsAsync;
    if (activeCircleId != null && activeCircleId.isNotEmpty) {
      circleDetailsAsync = ref.watch(circleDetailsProvider(activeCircleId));
    }

    AsyncValue<List<Map<String, dynamic>>>? raidAlertsAsync;
    if (activeCircleId != null && activeCircleId.isNotEmpty) {
      raidAlertsAsync = ref.watch(circleRaidAlertsProvider(activeCircleId));
    }

    final liveMessages = activeCircleId == null || activeCircleId.isEmpty
        ? null
        : ref.watch(circleMessagesProvider(activeCircleId));

    Map<String, dynamic>? circleData;
    List<dynamic>? leaderboardData;
    List<dynamic>? recentMessagesRaw;
    List<dynamic>? raidAlertsRaw;

    if (circleDetailsAsync != null && circleDetailsAsync.hasValue) {
      final data = circleDetailsAsync.value;
      if (data != null) {
        circleData = data['circle'] as Map<String, dynamic>?;
        leaderboardData = data['leaderboard'] as List<dynamic>?;
        final messagesCandidate = data['recent_messages'];
        if (messagesCandidate is List) {
          recentMessagesRaw = messagesCandidate;
        }
        final alertsCandidate = data['raid_alerts'];
        if (alertsCandidate is List) {
          raidAlertsRaw = alertsCandidate;
        }
      }
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final recentMessages = <ChatMessage>[
      if (liveMessages != null && liveMessages.messages.isNotEmpty)
        ..._parseRecentMessages(
          liveMessages.messages.take(8).toList(),
          currentUserId,
        )
      else if (recentMessagesRaw != null)
        ..._parseRecentMessages(recentMessagesRaw, currentUserId),
    ];

    final raidAlerts = <RaidAlert>[
      if (raidAlertsAsync != null && raidAlertsAsync.hasValue)
        ..._parseRaidAlerts(raidAlertsAsync.value ?? const [])
      else if (raidAlertsRaw != null)
        ..._parseRaidAlerts(raidAlertsRaw),
    ];

    final activeRaidCount = raidAlerts
        .where((alert) => alert.status == RaidStatus.activeAttack)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circles'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.fillColor, AppColors.bgLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

                // SeasonCountdownCard(
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) =>
                //             const SeasonRecapView(seasonId: 4, seasonName: '4'),
                //       ),
                //     );
                //   },
                // ),
                // 16.verticalSpace,
                if (circleDetailsAsync?.isLoading ?? false)
                  const _ShimmerLoading()
                else ...[
                  /// CIRCLE CARD
                  GuildCard(circle: circleData, leaderboard: leaderboardData),

                  16.verticalSpace,

                  /// LEADERBOARD
                  LeaderboardCard(leaderboard: leaderboardData),

                  16.verticalSpace,

                  /// SPECIAL RANKINGS
                  const SpecialRankingsSection(),

                  16.verticalSpace,
                  RaidAlertsCard(
                    alerts: raidAlerts,
                    activeCount: activeRaidCount,
                  ),
                  16.verticalSpace,

                  /// CHAT PREVIEW
                  CircleChatCard(
                    circleTitle:
                        circleData?['name']?.toString() ?? 'Circle Chat',
                    recentMessages: recentMessages,
                    unreadCount: 0,
                  ),

                  20.verticalSpace,

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Create a New Circle',
                      backgroundColor: AppColors.brandPurple,
                      textStyle: AppTextStyles.buttonLabel.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateCircleOnboardingView(),
                          ),
                        );
                      },
                    ),
                  ),

                  

                  SizedBox(height: 30.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.borderLight.withValues(alpha: 0.1),
                AppColors.borderLight.withValues(alpha: 0.4),
                AppColors.borderLight.withValues(alpha: 0.1),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Column(
        children: [
          Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26.r),
            ),
          ),
          16.verticalSpace,
          Container(
            height: 400.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1.0),
      0.0,
      0.0,
    );
  }
}
