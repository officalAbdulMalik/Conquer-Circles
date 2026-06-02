import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/features/profile/view/profile_view.dart';
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

  CircleCardTileData _circleUiData(Map<String, dynamic> circle, int index) {
    final name = circle['name']?.toString().trim();
    final maxMembers = (circle['max_members'] as int?) ?? 25;
    final minMembers = (circle['min_members'] as int?) ?? 3;
    final members =
        (circle['members'] as int?) ?? (minMembers + maxMembers) ~/ 2;
    final isPrivate = (circle['is_private'] as bool?) == true;
    final isMember = (circle['is_member'] as bool?) == true;
    final createdByMe = (circle['created_by_me'] as bool?) == true;
    final full = members >= maxMembers;
    final rank = (circle['rank'] as int?) ?? [2, 3, 6, 10][index % 4];

    return CircleCardTileData(
      id: circle['id']?.toString() ?? circle['circle_id']?.toString() ?? '',
      name: name?.isNotEmpty == true ? name! : _fallbackNames[index % 4],
      icon: _fallbackIcons[index % 4],
      iconBackground: _fallbackIconBackgrounds[index % 4],
      territory: index == 3 ? '64.3 km² Territory' : '48.2 km² Territory',
      membersLabel: '$members / $maxMembers Members',
      rank: rank,
      status: isMember
          ? CircleCardStatus.joined
          : createdByMe
          ? CircleCardStatus.active
          : isPrivate
          ? CircleCardStatus.private
          : full
          ? CircleCardStatus.full
          : CircleCardStatus.active,
      action: full
          ? CircleCardAction.full
          : isMember
          ? CircleCardAction.request
          : CircleCardAction.join,
    );
  }

  List<Map<String, dynamic>> _filteredCircles(
    List<Map<String, dynamic>> circles,
  ) {
    if (_selectedTab == 1) {
      return circles.where((c) => (c['is_member'] as bool?) == true).toList();
    }
    if (_selectedTab == 2) {
      return circles
          .where((c) => (c['created_by_me'] as bool?) == true)
          .toList();
    }
    if (_selectedTab == 3) {
      return circles.where((c) => (c['is_private'] as bool?) == true).toList();
    }
    return List<Map<String, dynamic>>.from(circles);
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);
    final allCircles = circlesState.allCircles;
    final visibleCircles = allCircles.isEmpty ? _previewCircles : allCircles;
    final filtered = allCircles.isEmpty
        ? _previewCircles
        : _filteredCircles(visibleCircles);
    final joinedCount = visibleCircles
        .where((c) => (c['is_member'] as bool?) == true)
        .length;
    final createdCount = visibleCircles
        .where((c) => (c['created_by_me'] as bool?) == true)
        .length;
    final privateCount = visibleCircles
        .where((c) => (c['is_private'] as bool?) == true)
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileView()),
                    );
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
                else if (filtered.isEmpty)
                  const EmptyCircleState()
                else
                  ...List.generate(filtered.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: CircleCardTile(
                        data: _circleUiData(filtered[index], index),
                        onTap: () {
                          final circleId =
                              filtered[index]['id']?.toString() ??
                              filtered[index]['circle_id']?.toString();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CirclesDetailsScreen(circleId: circleId),
                            ),
                          );
                        },
                        onRequestJoin: () {
                          showDialog<void>(
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

const _fallbackNames = [
  'StromWalker Team',
  'ShadowCore',
  'NeonStrike',
  'Night Striders',
];

const _fallbackIcons = ['⚡', '🛡️', '⚡', '🌙'];

const _fallbackIconBackgrounds = [
  Color(0xFFDDEBFF),
  Color(0xFFDDEBFF),
  Color(0xFFDDEBFF),
  Color(0xFFE8F0FF),
];

const _previewCircles = [
  {
    'id': 'stormwalker-preview',
    'name': 'StromWalker Team',
    'max_members': 20,
    'members': 14,
    'rank': 2,
  },
  {
    'id': 'shadowcore-preview',
    'name': 'ShadowCore',
    'is_private': true,
    'max_members': 20,
    'members': 14,
    'rank': 3,
  },
  {
    'id': 'neonstrike-preview',
    'name': 'NeonStrike',
    'max_members': 25,
    'members': 25,
    'rank': 6,
  },
  {
    'id': 'night-striders-preview',
    'name': 'Night Striders',
    'is_member': true,
    'max_members': 25,
    'members': 18,
    'rank': 10,
  },
];
