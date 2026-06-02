import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/features/social/view/circle_comms_view.dart';
import 'package:test_steps/features/social/widgets/circle_activity_list.dart';
import 'package:test_steps/features/social/widgets/circle_details_header.dart';
import 'package:test_steps/features/social/widgets/circle_details_loading.dart';
import 'package:test_steps/features/social/widgets/circle_join_requests_section.dart';
import 'package:test_steps/features/social/widgets/circle_leaderboard_list.dart';
import 'package:test_steps/features/social/widgets/circle_message_button.dart';
import 'package:test_steps/features/social/widgets/circle_metrics_row.dart';
import 'package:test_steps/providers/circles_provider.dart';

class CirclesDetailsScreen extends ConsumerWidget {
  const CirclesDetailsScreen({super.key, this.circleId});

  final String? circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCircleId =
        circleId ??
        ref
            .watch(circlesProvider)
            .circles
            .firstOrNull?['circle_id']
            ?.toString();
    final detailsAsync = activeCircleId == null
        ? null
        : ref.watch(circleDetailsProvider(activeCircleId));
    final details = detailsAsync?.hasValue == true ? detailsAsync?.value : null;
    final circle = details?['circle'] as Map<String, dynamic>?;
    final leaderboard = details?['leaderboard'] as List<dynamic>?;
    final requests = details?['requests'] as List<dynamic>?;
    final circleName = _circleName(circle);
    final currentUserId = ref.watch(currentCircleUserIdProvider);
    final isCreator =
        currentUserId != null &&
        circle?['owner_id']?.toString() == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 112.h),
              children: [
                if (detailsAsync?.isLoading ?? false)
                  const CircleDetailsLoading()
                else ...[
                  CircleDetailsHeader(
                    name: circleName,
                    status: _statusLabel(circle),
                    onBack: () => Navigator.maybePop(context),
                  ),
                  16.verticalSpace,
                  CircleMetricsRow(metrics: _metrics(circle)),
                  if (isCreator) ...[
                    18.verticalSpace,
                    CircleJoinRequestsSection(
                      requests: _joinRequests(requests),
                    ),
                  ],
                  18.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Leaderboard',
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(18.r),
                        onTap: () {},
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          child: Text(
                            'View All',
                            style: AppTextStyles.montserrat(
                              size: 12.sp,
                              color: AppColors.blueColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  CircleLeaderboardList(
                    members: _leaderboardMembers(leaderboard),
                  ),
                  24.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Activity',
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(18.r),
                        onTap: () {},
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          child: Text(
                            'View All',
                            style: AppTextStyles.montserrat(
                              size: 12.sp,
                              color: AppColors.blueColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  10.verticalSpace,
                  CircleActivityList(items: _activityItems),
                ],
              ],
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 16.h,
            child: SafeArea(
              top: false,
              child: CircleMessageButton(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CircleCommsView(
                        circleId: activeCircleId ?? '',
                        circleName: circleName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _circleName(Map<String, dynamic>? circle) {
    final name = circle?['name']?.toString().trim();
    return name?.isNotEmpty == true ? name! : 'StromWalker Team';
  }

  String _statusLabel(Map<String, dynamic>? circle) {
    final isPrivate = (circle?['is_private'] as bool?) == true;
    return isPrivate ? 'Private' : 'Active';
  }

  List<CircleDetailMetric> _metrics(Map<String, dynamic>? circle) {
    final maxMembers = (circle?['max_members'] as int?) ?? 25;
    final members = (circle?['members'] as int?) ?? 14;

    return [
      const CircleDetailMetric(
        icon: 'assets/images/rank.png',
        label: 'Rank',
        value: '#2',
      ),
      const CircleDetailMetric(
        icon: 'assets/images/terr.png',
        label: 'Territory',
        value: '48.2 km²',
      ),
      CircleDetailMetric(
        icon: 'assets/images/member.png',
        label: 'Members',
        value: '$members / $maxMembers',
      ),
    ];
  }

  List<CircleLeaderboardMember> _leaderboardMembers(
    List<dynamic>? leaderboard,
  ) {
    if (leaderboard == null || leaderboard.isEmpty) return _previewLeaderboard;

    return leaderboard.take(4).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final name =
          item['username']?.toString() ??
          item['name']?.toString() ??
          _previewLeaderboard[index % _previewLeaderboard.length].name;
      final score = (item['score'] as num?)?.toInt() ?? 950 - index * 37;

      return CircleLeaderboardMember(
        name: name,
        rank: '#${index + 1}',
        score: score,
        avatar: _previewLeaderboard[index % _previewLeaderboard.length].avatar,
        medal: index < 3 ? _previewLeaderboard[index].medal : null,
        isCurrentUser: index == 2,
      );
    }).toList();
  }

  List<CircleJoinRequest> _joinRequests(List<dynamic>? requests) {
    if (requests == null || requests.isEmpty) return _previewJoinRequests;

    return requests.toList().asMap().entries.map((entry) {
      final item = entry.value as Map<String, dynamic>;
      return CircleJoinRequest(
        id: item['id']?.toString() ?? 'request-${entry.key}',
        name:
            item['username']?.toString() ??
            item['name']?.toString() ??
            'Circle member',
        avatar: item['avatar']?.toString() ?? '👤',
      );
    }).toList();
  }
}

const _previewJoinRequests = [
  CircleJoinRequest(id: 'ali-raza', name: 'Ali Raza', avatar: '👨🏼'),
  CircleJoinRequest(id: 'haider-malik', name: 'Haider Malik', avatar: '🧑🏽'),
];

const _previewLeaderboard = [
  CircleLeaderboardMember(
    name: 'Aqib Javid',
    rank: '#1',
    score: 950,
    avatar: '👨🏽',
    medal: '🥇',
  ),
  CircleLeaderboardMember(
    name: 'Sarah Ahmed',
    rank: '#2',
    score: 901,
    avatar: '👩🏼',
    medal: '🥈',
  ),
  CircleLeaderboardMember(
    name: 'Micheal Waliam',
    rank: '#3',
    score: 879,
    avatar: '🧔🏽',
    medal: '🥉',
    isCurrentUser: true,
  ),
  CircleLeaderboardMember(
    name: 'Asim Kamal',
    rank: '#4',
    score: 843,
    avatar: '👨🏻',
  ),
];

const _activityItems = [
  CircleActivityItem(
    title: 'Alex captured +0.8 km² near Downtown',
    subtitle: '22 min ago · Northwest edge',
  ),
  CircleActivityItem(
    title: 'Sarah successfully defended the North side',
    subtitle: '22 min ago · Northwest edge',
  ),
  CircleActivityItem(
    title: 'You climbed to #4 in your Circle after a walk',
    subtitle: '22 min ago · position up',
  ),
  CircleActivityItem(
    title: 'Night Striders reached a new energy bonus',
    subtitle: '1 hr ago · 200 energy',
  ),
];
