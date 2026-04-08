import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/widgets/session_progress_bar.dart';
import 'package:test_steps/features/social/widgets/terriorty_tile.dart';
import '../widgets/info_tile.dart';
import '../widgets/section_card.dart';


class CircleProfileScreen extends StatefulWidget {
  const CircleProfileScreen({super.key});

  @override
  State<CircleProfileScreen> createState() => _CircleProfileScreenState();
}

class _CircleProfileScreenState extends State<CircleProfileScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Members (3)', 'Activity'];

  // Sample territory data: 22 owned, 1 contested, rest neutral
  List<TerritoryStatus> get _territories {
    final List<TerritoryStatus> tiles = [];
    for (int i = 0; i < 28; i++) {
      if (i < 22) {
        tiles.add(TerritoryStatus.owned);
      } else if (i == 22) {
        tiles.add(TerritoryStatus.contested);
      } else {
        tiles.add(TerritoryStatus.neutral);
      }
    }
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ─── APP BAR ───
                SliverToBoxAdapter(child: _buildAppBar()),

                // ─── CIRCLE HEADER ───
                SliverToBoxAdapter(child: _buildCircleHeader()),

                // ─── SEASON PROGRESS ───
                SliverToBoxAdapter(
                  child: SeasonProgressBar(
                    seasonLabel: 'Season 4 Progress',
                    currentXP: 198000,
                    targetXP: 300000,
                  ),
                ),

                // ─── STATS ROW ───
                SliverToBoxAdapter(child: _buildStatsRow()),

                // ─── REQUIREMENTS ───
                SliverToBoxAdapter(child: _buildRequirements()),

                // ─── TABS ───
                SliverToBoxAdapter(child: _buildTabs()),

                // ─── TAB CONTENT ───
                SliverToBoxAdapter(child: _buildTabContent()),

                // ─── BOTTOM PADDING for FAB ───
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // ─── BOTTOM ACTION BAR ───
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {},
          ),
          const Spacer(),
          _IconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _IconButton(
            icon: Icons.share_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CIRCLE HEADER (Avatar + name + rank + location)
  // ─────────────────────────────────────────────
  Widget _buildCircleHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                     Text('NeonStrike', style: AppTextStyles.heading1),
                    const SizedBox(width: 8),
                    _RankBadge(rank: '#3'),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '"Neon streets, neon dreams."',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                     Text('West Side', style: AppTextStyles.caption),
                    const SizedBox(width: 10),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                     Text('2 online', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STATS ROW
  // ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InfoTile(
              variant: TileVariant.stat,
              icon: Icons.group_outlined,
              iconColor: AppColors.primary,
              value: '14',
              subValue: '/20',
              label: 'Members',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InfoTile(
              variant: TileVariant.stat,
              icon: Icons.location_on_outlined,
              iconColor: AppColors.blue,
              value: '22',
              label: 'Territories',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InfoTile(
              variant: TileVariant.stat,
              icon: Icons.emoji_events_outlined,
              iconColor: AppColors.yellow,
              value: '31',
              label: 'Season Wins',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InfoTile(
              variant: TileVariant.stat,
              icon: Icons.flash_on_rounded,
              iconColor: AppColors.orange,
              value: '22',
              label: 'Raids Won',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REQUIREMENTS
  // ─────────────────────────────────────────────
  Widget _buildRequirements() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.star_outline_rounded,
            title: 'Requirements to Join',
          ),
          const Divider(height: 16, color: AppColors.divider),
          InfoTile(
            variant: TileVariant.requirement,
            label: 'Minimum Level 8',
            isMet: true,
            statusText: 'Met',
          ),
          const Divider(height: 1, color: AppColors.divider),
          InfoTile(
            variant: TileVariant.requirement,
            label: '3-day active streak',
            isMet: true,
            statusText: 'Met',
          ),
          const Divider(height: 1, color: AppColors.divider),
          InfoTile(
            variant: TileVariant.requirement,
            label: 'Playstyle: Balanced',
            isMet: true,
            statusText: 'Met',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TABS
  // ─────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 0)
                        Icon(
                          Icons.grid_view_rounded,
                          size: 13,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      if (index == 1)
                        Icon(
                          Icons.people_outline_rounded,
                          size: 13,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      if (index == 2)
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT
  // ─────────────────────────────────────────────
  Widget _buildTabContent() {
    if (_selectedTab != 0) {
      return SectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _selectedTab == 1 ? 'Members list coming soon' : 'Activity feed coming soon',
              style: AppTextStyles.splashHeading,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Territory Control
        SectionCard(
          child: Column(
            children: [
              SectionHeader(
                icon: Icons.location_on_outlined,
                title: 'Territory Control',
                actionLabel: 'View Map',
                onAction: () {},
              ),
              const SizedBox(height: 14),
              TerritoryGrid(tiles: _territories),
            ],
          ),
        ),

        // Circle Chat
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Circle Chat',
                indicator: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.online,
                    shape: BoxShape.circle,
                  ),
                ),
                actionLabel: 'Preview',
                onAction: () {},
              ),
              const SizedBox(height: 12),
              InfoTile(
                variant: TileVariant.chatMessage,
                username: 'IronStrider',
                timeAgo: '2m ago',
                message: 'South Shore is under attack! Need backup 🔥',
                avatarColor: AppColors.orange,
              ),
              const Divider(height: 8, color: AppColors.divider),
              InfoTile(
                variant: TileVariant.chatMessage,
                username: 'SwiftBlaze',
                timeAgo: '1m ago',
                message: 'On my way, 14k steps done 💪',
                avatarColor: const Color(0xFFEF4444),
              ),
              const Divider(height: 8, color: AppColors.divider),
              InfoTile(
                variant: TileVariant.chatMessage,
                username: 'FitWarrior',
                timeAgo: 'just now',
                message: 'GG team, season ends in 3 days. PUSH!',
                avatarColor: const Color(0xFF374151),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Join to participate in circle chat',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),

        // Season Leaderboard
        SectionCard(
          child: Column(
            children: [
              SectionHeader(
                icon: Icons.emoji_events_outlined,
                iconColor: AppColors.yellow,
                title: 'Season Leaderboard',
              ),
              const SizedBox(height: 8),
              InfoTile(
                variant: TileVariant.leaderboard,
                rank: 1,
                label: 'StormWalkers',
                trailingValue: '284k XP',
                trailingColor: AppColors.blue,
                leadingWidget: _LeaderboardAvatar(
                  icon: Icons.bolt_rounded,
                  color: AppColors.yellow,
                ),
              ),
              InfoTile(
                variant: TileVariant.leaderboard,
                rank: 2,
                label: 'IronVault',
                trailingValue: '261k XP',
                trailingColor: AppColors.green,
                leadingWidget: _LeaderboardAvatar(
                  icon: Icons.shield_outlined,
                  color: AppColors.orange,
                ),
              ),
              InfoTile(
                variant: TileVariant.leaderboard,
                rank: 3,
                label: 'NeonStrike',
                trailingValue: '198k XP',
                trailingColor: AppColors.primary,
                isCurrentUser: true,
                leadingWidget: _LeaderboardAvatar(
                  icon: Icons.favorite_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Join Circle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
           Text(
            '6 spots left · Join before it\'s full!',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final String rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 11, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            'Rank $rank',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LeaderboardAvatar({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}