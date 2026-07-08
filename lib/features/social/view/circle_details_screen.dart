import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/features/social/models/circle_models.dart';
import 'package:test_steps/features/social/view/circle_comms_view.dart';
import 'package:test_steps/features/social/widgets/circle_activity_list.dart';
import 'package:test_steps/features/social/widgets/circle_admin_options_sheet.dart';
import 'package:test_steps/features/social/widgets/circle_details_header.dart';
import 'package:test_steps/features/social/widgets/circle_details_loading.dart';
import 'package:test_steps/features/social/widgets/circle_join_requests_section.dart';
import 'package:test_steps/features/social/widgets/circle_leaderboard_list.dart';
import 'package:test_steps/features/social/widgets/circle_message_button.dart';
import 'package:test_steps/features/social/widgets/circle_metrics_row.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class CirclesDetailsScreen extends ConsumerWidget {
  const CirclesDetailsScreen({super.key, this.circleId});

  final String? circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCircleId =
        circleId ?? ref.watch(circlesProvider).circles.firstOrNull?.id;
    final detailsAsync = activeCircleId == null
        ? null
        : ref.watch(circleDetailsProvider(activeCircleId));
    final details = detailsAsync?.hasValue == true ? detailsAsync?.value : null;
    final circle = details?.circle;
    final circlesState = ref.watch(circlesProvider);
    final circleName = circle?.name ?? 'Unnamed Circle';
    final currentUserId = ref.watch(currentCircleUserIdProvider);
    final displayMembers = _leaderboardMembers(
      details?.members ?? const [],
      currentUserId,
    );
    final isCreator = currentUserId != null && circle?.ownerId == currentUserId;
    final requests = activeCircleId == null
        ? const <CircleJoinRequestModel>[]
        : circlesState.incomingJoinRequests
              .where((request) => request.circleId == activeCircleId)
              .toList();

    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(),
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
                    members: displayMembers,
                    onBack: () => Navigator.maybePop(context),
                    onOptions: isCreator
                        ? () => _showAdminOptions(context)
                        : null,
                  ),
                  16.verticalSpace,
                  CircleMetricsRow(
                    metrics: _metrics(circle),
                    circleName: circleName,
                    members: displayMembers,
                    canRemoveMembers: isCreator,
                    removingMemberIds: circlesState.removingMemberIds,
                    onRemoveMember: activeCircleId == null
                        ? null
                        : (memberId) async {
                            final response = await ref
                                .read(circlesProvider.notifier)
                                .removeCircleMember(
                                  circleId: activeCircleId,
                                  memberId: memberId,
                                );
                            if (response['success'] == true) {
                              ref.invalidate(
                                circleDetailsProvider(activeCircleId),
                              );
                            }
                            return response;
                          },
                  ),
                  if (isCreator) ...[
                    18.verticalSpace,
                    CircleJoinRequestsSection(
                      requests: _joinRequests(requests),
                      respondingRequestIds: circlesState.respondingRequestIds,
                      onAccept: (requestId) async {
                        final response = await ref
                            .read(circlesProvider.notifier)
                            .respondToJoinRequest(
                              requestId: requestId,
                              accept: true,
                            );
                        if (response['success'] == true) {
                          ref.invalidate(
                            circleDetailsProvider(activeCircleId!),
                          );
                        }
                      },
                      onDelete: (requestId) => ref
                          .read(circlesProvider.notifier)
                          .respondToJoinRequest(
                            requestId: requestId,
                            accept: false,
                          ),
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
                  CircleLeaderboardList(members: displayMembers),
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
                        members: displayMembers,
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

  String _statusLabel(CircleModel? circle) =>
      circle?.isPrivate == true ? 'Private' : 'Active';

  void _showAdminOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => CircleAdminOptionsSheet(
        onBlockChat: () => Navigator.pop(sheetContext),
        onEditCircle: () => Navigator.pop(sheetContext),
        onDeleteCircle: () => Navigator.pop(sheetContext),
      ),
    );
  }

  List<CircleDetailMetric> _metrics(CircleModel? circle) {
    return [
      CircleDetailMetric(
        icon: 'assets/images/rank.png',
        label: 'Rank',
        value: circle == null || circle.rank <= 0 ? '#-' : '#${circle.rank}',
      ),
      CircleDetailMetric(
        icon: 'assets/images/terr.png',
        label: 'Territory',
        value: '${circle?.territories ?? 0}',
      ),
      CircleDetailMetric(
        icon: 'assets/images/member.png',
        label: 'Members',
        value: '${circle?.memberCount ?? 0} / ${circle?.maxMembers ?? 25}',
      ),
    ];
  }

  List<CircleLeaderboardMember> _leaderboardMembers(
    List<CircleMemberModel> members,
    String? currentUserId,
  ) {
    return members.asMap().entries.map((entry) {
      final index = entry.key;
      final member = entry.value;

      return CircleLeaderboardMember(
        userId: member.userId,
        name: member.name,
        rank: '#${index + 1}',
        score: member.attackEnergy,
        avatar: '👤',
        avatarUrl: member.avatarUrl,
        role: member.role,
        medal: index < _leaderboardMedals.length
            ? _leaderboardMedals[index]
            : null,
        isCurrentUser: currentUserId != null && member.userId == currentUserId,
      );
    }).toList();
  }

  List<CircleJoinRequest> _joinRequests(List<CircleJoinRequestModel> requests) {
    return requests.map((request) {
      return CircleJoinRequest(
        id: request.id,
        name: request.requesterName,
        avatar: '👤',
        avatarUrl: request.avatarUrl,
      );
    }).toList();
  }
}

const _leaderboardMedals = ['🥇', '🥈', '🥉'];

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
