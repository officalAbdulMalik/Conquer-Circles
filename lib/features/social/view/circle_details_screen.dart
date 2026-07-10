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
import 'package:test_steps/features/social/widgets/request_sent_dialog.dart';
import 'package:test_steps/features/steps/view/overview_stats_section.dart';
import 'package:test_steps/services/dashboard_service.dart';
import 'package:test_steps/providers/stats_range_provider.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CirclesDetailsScreen extends ConsumerStatefulWidget {
  const CirclesDetailsScreen({super.key, this.circleId});

  final String? circleId;

  @override
  ConsumerState<CirclesDetailsScreen> createState() => _CirclesDetailsScreenState();
}

class _CirclesDetailsScreenState extends ConsumerState<CirclesDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsRangeProvider.notifier).loadStatsGraph();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCircleId =
        widget.circleId ?? ref.watch(circlesProvider).circles.firstOrNull?.id;
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
    final isJoined = isCreator || (circle?.isMember ?? false);
    final requests = activeCircleId == null
        ? const <CircleJoinRequestModel>[]
        : circlesState.incomingJoinRequests
              .where((request) => request.circleId == activeCircleId)
              .toList();

    final hasPendingRequest = (circle?.joinRequestStatus == 'pending') ||
        (activeCircleId != null &&
            circlesState.joinRequestStatuses[activeCircleId] == 'pending');

    // Stats Overview:
    final dashboardState = ref.watch(dashboardProvider);
    final statsRange = ref.watch(statsRangeProvider);
    final rangeNotifier = ref.read(statsRangeProvider.notifier);

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
                        ? () => _showAdminOptions(
                            context,
                            ref,
                            activeCircleId,
                            circleName,
                          )
                        : null,
                  ),
                  if (isJoined) ...[
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
                    24.verticalSpace,
                    OverviewStatsSection(
                      distanceDays: dashboardState.distanceGraphDays,
                      isDistanceLoading: dashboardState.isGraphLoading,
                      distanceError: dashboardState.graphError,
                      territoryDays: dashboardState.territoryGraphDays,
                      isTerritoryLoading: dashboardState.isTerritoryGraphLoading,
                      territoryError: dashboardState.territoryGraphError,
                      selectedRange: statsRange.range,
                      periodStart: statsRange.periodStart,
                      periodEnd: statsRange.periodEnd,
                      canNavigatePrevious: statsRange.range != DashboardStatsRange.allTime,
                      canNavigateNext: statsRange.canNavigateNext,
                      onRangeChanged: rangeNotifier.selectRange,
                      onPreviousPeriod: () => rangeNotifier.changePeriod(-1),
                      onNextPeriod: () => rangeNotifier.changePeriod(1),
                      onRetryDistance: rangeNotifier.loadStatsGraph,
                    ),
                  ] else ...[
                    _LockedCircleView(
                      circleId: activeCircleId ?? '',
                      hasPendingRequest: hasPendingRequest,
                      isJoining: circlesState.requestingCircleIds.contains(activeCircleId),
                      onRequestJoin: () async {
                        if (activeCircleId == null) return;
                        final result = await ref
                            .read(circlesProvider.notifier)
                            .requestToJoinCircle(activeCircleId);
                        if (!context.mounted) return;
                        if (result['success'] != true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['error']?.toString() ?? 'Could not send join request',
                              ),
                            ),
                          );
                          return;
                        }
                        await showDialog<void>(
                          context: context,
                          builder: (_) => const RequestSentDialog(),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (isJoined)
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
                          isCreator: isCreator,
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

  void _showAdminOptions(
    BuildContext context,
    WidgetRef ref,
    String? circleId,
    String circleName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => CircleAdminOptionsSheet(
        onEditCircle: () => Navigator.pop(sheetContext),
        onDeleteCircle: () {
          Navigator.pop(sheetContext);
          if (circleId != null) {
            _confirmDeleteCircle(context, ref, circleId, circleName);
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteCircle(
    BuildContext context,
    WidgetRef ref,
    String circleId,
    String circleName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteCircleDialog(circleName: circleName),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(circlesProvider.notifier).deleteCircle(circleId);
    if (!context.mounted) return;

    final error = ref.read(circlesProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).maybePop();
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

class _DeleteCircleDialog extends StatelessWidget {
  const _DeleteCircleDialog({required this.circleName});

  final String circleName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 22.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26.r),
          border: AppBorders.raised(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blueColor, AppColors.blueColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blueColor.withValues(alpha: 0.4),
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 30.sp,
                color: Colors.white,
              ),
            ),
            16.verticalSpace,
            Text(
              'Delete $circleName',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 19.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            14.verticalSpace,
            Text(
              'Are you sure want to delete\n$circleName circle, once deleted will\nnot be restored.',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            20.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blueColor,
                        side: BorderSide(color: AppColors.blueColor, width: 2.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.blueColor,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                14.horizontalSpace,
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFEE3F5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

class _LockedCircleView extends StatelessWidget {
  const _LockedCircleView({
    required this.circleId,
    required this.hasPendingRequest,
    required this.isJoining,
    required this.onRequestJoin,
  });

  final String circleId;
  final bool hasPendingRequest;
  final bool isJoining;
  final VoidCallback onRequestJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: const BoxDecoration(
              color: AppColors.blueContiner,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPendingRequest ? Icons.hourglass_empty_rounded : Icons.lock_outline_rounded,
              color: AppColors.blueColor,
              size: 36.sp,
            ),
          ),
          20.verticalSpace,
          Text(
            hasPendingRequest ? 'Join Request Pending' : 'Join this Circle',
            style: AppTextStyles.montserrat(
              size: 18.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
          10.verticalSpace,
          Text(
            hasPendingRequest
                ? 'Your request to join this Circle is currently pending review by the administrator.'
                : 'You must be a member of this Circle to view its metrics, leaderboard, recent activity, and chat.',
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          24.verticalSpace,
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: (hasPendingRequest || isJoining) ? null : onRequestJoin,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.blueColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFFF4D8),
                disabledForegroundColor: const Color(0xFFB7791F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              child: isJoining
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      hasPendingRequest ? 'Request Sent' : 'Request to Join',
                      style: AppTextStyles.montserrat(
                        size: 15.sp,
                        color: hasPendingRequest ? const Color(0xFFB7791F) : Colors.white,
                        weight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
