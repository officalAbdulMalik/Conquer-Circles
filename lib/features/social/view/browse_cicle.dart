import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/features/profile/view/profile_bottom_sheet.dart';
import 'package:test_steps/features/social/models/circle_models.dart';
import 'package:test_steps/features/social/view/create_circle_onboarding_view.dart';
import 'package:test_steps/features/social/view/circle_details_screen.dart';
import 'package:test_steps/features/social/widgets/circle_card_tile.dart';
import 'package:test_steps/features/social/widgets/circle_search_field.dart';
import 'package:test_steps/features/social/widgets/create_circle_button.dart';
import 'package:test_steps/features/social/widgets/empty_circle_state.dart';
import 'package:test_steps/features/social/widgets/request_sent_dialog.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/widgets/shared/dashboard_screen_header.dart';
import 'package:test_steps/widgets/shared/dashboard_tab_button.dart';

class AllCirclesPage extends ConsumerStatefulWidget {
  const AllCirclesPage({super.key});

  @override
  ConsumerState<AllCirclesPage> createState() => _AllCirclesPageState();
}

class _AllCirclesPageState extends ConsumerState<AllCirclesPage> {
  int _selectedTab = 0;

  final _tabs = const [
    ('All', null),
    ('Joined', null),
    ('Created', null),
    ('Private', null),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(circlesProvider.notifier).refreshAllCircles();
    });
  }

  CircleCardTileData _circleUiData(CircleModel circle, int index) {
    return CircleCardTileData(
      id: circle.id,
      name: circle.name,
      icon: _fallbackIcons[index % 4],
      iconUrl: circle.imageUrl,
      iconBackground: _fallbackIconBackgrounds[index % 4],
      territory: '${circle.territories} Territories',
      membersLabel: '${circle.memberCount} / ${circle.maxMembers} Members',
      memberNames: circle.members.map((member) => member.name).toList(),
      memberAvatarUrls: circle.members
          .map((member) => member.avatarUrl)
          .toList(),
      rank: circle.rank > 0 ? circle.rank : index + 1,
      status: circle.isMember
          ? CircleCardStatus.joined
          : circle.createdByMe
          ? CircleCardStatus.active
          : circle.hasPendingJoinRequest
          ? CircleCardStatus.requested
          : circle.isPrivate
          ? CircleCardStatus.private
          : circle.isFull
          ? CircleCardStatus.full
          : CircleCardStatus.active,
      action: circle.isFull
          ? CircleCardAction.full
          : circle.isMember
          ? CircleCardAction.request
          : circle.createdByMe || circle.hasPendingJoinRequest
          ? CircleCardAction.request
          : CircleCardAction.join,
    );
  }

  List<CircleModel> _filteredCircles(List<CircleModel> circles) {
    if (_selectedTab == 1) {
      return circles.where((circle) => circle.isMember).toList();
    }
    if (_selectedTab == 2) {
      return circles.where((circle) => circle.createdByMe).toList();
    }
    if (_selectedTab == 3) {
      return circles.where((circle) => circle.isPrivate).toList();
    }
    return List<CircleModel>.from(circles);
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);
    final allCircles = circlesState.allCircles;
    final visibleCircles = allCircles;
    final filtered = _filteredCircles(visibleCircles);
    final joinedCount = visibleCircles
        .where((circle) => circle.isMember)
        .length;
    final createdCount = visibleCircles
        .where((circle) => circle.createdByMe)
        .length;
    final privateCount = visibleCircles
        .where((circle) => circle.isPrivate)
        .length;
    final tabCounts = [
      visibleCircles.length,
      joinedCount,
      createdCount,
      privateCount,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
              children: [
                DashboardScreenHeader(
                  title: 'Circles',
                  energy: 69,
                  onNotificationsTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  onProfileTap: () {
                    showProfileBottomSheet(context);
                  },
                ),
                26.verticalSpace,
                const CircleSearchField(),
                18.verticalSpace,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: DashboardTabButton(
                          label: _tabs[index].$1,
                          count: index == 0 ? null : tabCounts[index],
                          selected: _selectedTab == index,
                          onTap: () => setState(() => _selectedTab = index),
                        ),
                      );
                    }),
                  ),
                ),
                22.verticalSpace,
                if (circlesState.isLoading && allCircles.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (circlesState.error != null && allCircles.isEmpty)
                  _CirclesLoadError(
                    onRetry: () =>
                        ref.read(circlesProvider.notifier).refreshAllCircles(),
                  )
                else if (filtered.isEmpty)
                  const EmptyCircleState()
                else
                  ...List.generate(filtered.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: CircleCardTile(
                        data: _circleUiData(filtered[index], index),
                        isRequesting: circlesState.requestingCircleIds.contains(
                          filtered[index].id,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CirclesDetailsScreen(
                                circleId: filtered[index].id,
                              ),
                            ),
                          );
                        },
                        onRequestJoin: () async {
                          final result = await ref
                              .read(circlesProvider.notifier)
                              .requestToJoinCircle(filtered[index].id);
                          if (!context.mounted) {
                            return;
                          }
                          if (result['success'] != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['error']?.toString() ??
                                      'Could not send join request',
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
                    );
                  }),
              ],
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 16.h,
            child: SafeArea(
              top: false,
              child: CreateCircleButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCircleOnboardingView(),
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
}

class _CirclesLoadError extends StatelessWidget {
  const _CirclesLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 36.h),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 42.sp,
            color: const Color(0xFF667085),
          ),
          12.verticalSpace,
          Text(
            'Circles could not be loaded',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF101828),
            ),
          ),
          6.verticalSpace,
          Text(
            'Check the circles table access and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF667085)),
          ),
          10.verticalSpace,
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

const _fallbackIcons = ['⚡', '🛡️', '⚡', '🌙'];

const _fallbackIconBackgrounds = [
  Color(0xFFDDEBFF),
  Color(0xFFDDEBFF),
  Color(0xFFDDEBFF),
  Color(0xFFE8F0FF),
];
