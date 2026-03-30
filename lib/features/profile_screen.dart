import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/subscription_provider.dart';
import './seasons/view/season_recap_view.dart';
import './subscription/view/premium_paywall_view.dart';
import '../models/badge_model.dart';
import '../providers/badge_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final subscription = ref.watch(subscriptionProvider);

    print('subscription: ${subscription.isPremium}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!subscription.isPremium)
            TextButton.icon(
              onPressed: () => _showPaywall(context),
              icon: const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
              label: const Text(
                'UPGRADE',
                style: TextStyle(color: Color(0xFFFFD700)),
              ),
            ),
        ],
      ),
      body: subscription.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(subscriptionProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subscription.profile?.username ?? user?.email ?? 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subscription.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Grid
                  _buildStatsGrid(subscription.profile),

                  const SizedBox(height: 32),

                  // Badges Section
                  _buildBadgeSection(context, ref),

                  const SizedBox(height: 32),

                  // Advanced Analytics Preview (Upsell)
                  _buildAnalyticsUpsell(context, subscription.isPremium),

                  const SizedBox(height: 32),

                  const Text(
                    'REWARDS & HISTORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: Color(0xFFFFD700),
                    ),
                    title: const Text('Season 1 Recap'),
                    subtitle: const Text('View your achievements and rewards'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SeasonRecapView(
                            seasonId: 1,
                            seasonName: '1',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Health History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PremiumPaywallView(),
    );
  }

  Widget _buildStatsGrid(dynamic profile) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        // Placeholder for future stats
      ],
    );
  }

  Widget _buildBadgeSection(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(unlockedBadgesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACHIEVEMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        badgesAsync.when(
          data: (unlockedBadges) {
            final unlockedIds = unlockedBadges.map((b) => b.id).toSet();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: BadgeModel.allBadgeIds.length,
              itemBuilder: (context, index) {
                final badgeId = BadgeModel.allBadgeIds[index];
                final isUnlocked = unlockedIds.contains(badgeId);

                return GestureDetector(
                  onTap: () => _showBadgeDetails(context, badgeId, isUnlocked),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.teal.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.teal.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getBadgeIcon(badgeId),
                        style: TextStyle(
                          fontSize: 24,
                          color: isUnlocked
                              ? null
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, stack) => Text('Error: $e'),
        ),
      ],
    );
  }

  void _showBadgeDetails(
    BuildContext context,
    String badgeId,
    bool isUnlocked,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isUnlocked ? 'Achievement Unlocked!' : 'Locked Achievement',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getBadgeIcon(badgeId),
              style: TextStyle(
                fontSize: 64,
                color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getBadgeTitle(badgeId),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getBadgeDescription(badgeId),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep playing to unlock this badge!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  String _getBadgeIcon(String id) {
    switch (id) {
      case 'step_rookie': return '👟';
      case 'daily_grinder': return '🔥';
      case 'marathon_walker': return '🏁';
      case 'territory_pioneer': return '🚩';
      case 'territory_builder': return '🧱';
      case 'expansion_master': return '👑';
      case 'raid_initiator': return '⚔️';
      case 'raid_champion': return '🏆';
      case 'raid_destroyer': return '💥';
      case 'defense_architect': return '🏗️';
      case 'fortress_master': return '🏰';
      case 'cluster_creator': return '💠';
      case 'territory_emperor': return '🌎';
      case 'comeback_king': return '🔄';
      case 'early_bird': return '🌅';
      case 'night_walker': return '🌙';
      case 'consistency_hero': return '📅';
      case 'energy_hoarder': return '🔋';
      case 'war_hero': return '🎖️';
      case 'expansion_legend': return '📈';
      case 'defender': return '🛡️';
      case 'rival_slayer': return '🎯';
      case 'territory_guardian': return '💂';
      case 'park_explorer': return '🌳';
      case 'street_king': return '🛣️';
      case 'strategic_raider': return '🧠';
      case 'weekend_warrior': return '⚡';
      case 'circle_champion': return '🥇';
      case 'grand_conqueror': return '💎';
      case 'season_legend': return '🌟';
      default: return '❓';
    }
  }

  String _getBadgeTitle(String id) {
    switch (id) {
      case 'step_rookie': return '1 Step Rookie';
      case 'daily_grinder': return '2 Daily Grinder';
      case 'marathon_walker': return '3 Marathon Walker';
      case 'territory_pioneer': return '4 Territory Pioneer';
      case 'territory_builder': return '5 Territory Builder';
      case 'expansion_master': return '6 Expansion Master';
      case 'raid_initiator': return '7 Raid Initiator';
      case 'raid_champion': return '8 Raid Champion';
      case 'raid_destroyer': return '9 Raid Destroyer';
      case 'defense_architect': return '10 Defense Architect';
      case 'fortress_master': return '11 Fortress Master';
      case 'cluster_creator': return '12 Cluster Creator';
      case 'territory_emperor': return '13 Territory Emperor';
      case 'comeback_king': return '14 Comeback King';
      case 'early_bird': return '15 Early Bird';
      case 'night_walker': return '16 Night Walker';
      case 'consistency_hero': return '17 Consistency Hero';
      case 'energy_hoarder': return '18 Energy Hoarder';
      case 'war_hero': return '19 War Hero';
      case 'expansion_legend': return '20 Expansion Legend';
      case 'defender': return '21 Defender';
      case 'rival_slayer': return '22 Rival Slayer';
      case 'territory_guardian': return '23 Territory Guardian';
      case 'park_explorer': return '24 Park Explorer';
      case 'street_king': return '25 Street King';
      case 'strategic_raider': return '26 Strategic Raider';
      case 'weekend_warrior': return '27 Weekend Warrior';
      case 'circle_champion': return '28 Circle Champion';
      case 'grand_conqueror': return '29 Grand Conqueror';
      case 'season_legend': return '30 Season Legend';
      default: return 'Achievement';
    }
  }

  String _getBadgeDescription(String id) {
    switch (id) {
      case 'step_rookie': return 'Walk 5,000 steps in one day.';
      case 'daily_grinder': return 'Walk 10,000 steps for 5 days in a row.';
      case 'marathon_walker': return 'Walk 42 km total in a season.';
      case 'territory_pioneer': return 'Capture 10 tiles.';
      case 'territory_builder': return 'Capture 50 tiles.';
      case 'expansion_master': return 'Capture 100 tiles.';
      case 'raid_initiator': return 'Launch first territory attack.';
      case 'raid_champion': return 'Win 10 raids.';
      case 'raid_destroyer': return 'Win 25 raids.';
      case 'defense_architect': return 'Upgrade 10 tiles to max energy.';
      case 'fortress_master': return 'Hold a tile with 60 energy.';
      case 'cluster_creator': return 'Create a cluster of 7 tiles.';
      case 'territory_emperor': return 'Control 25 tiles simultaneously.';
      case 'comeback_king': return 'Lose territory then reclaim it within 24 hours.';
      case 'early_bird': return 'Walk before 7 AM for 7 days.';
      case 'night_walker': return 'Walk after 10 PM for 5 days.';
      case 'consistency_hero': return 'Walk every day for 14 days.';
      case 'energy_hoarder': return 'Store maximum attack energy.';
      case 'war_hero': return 'Win 15 raids in war phase.';
      case 'expansion_legend': return 'Capture 10 new tiles in one day.';
      case 'defender': return 'Successfully defend tile 10 times.';
      case 'rival_slayer': return 'Capture territory from same rival 5 times.';
      case 'territory_guardian': return 'Hold territory for entire season.';
      case 'park_explorer': return 'Capture 5 park tiles.';
      case 'street_king': return 'Control an entire street cluster.';
      case 'strategic_raider': return 'Capture tile with exactly equal energy.';
      case 'weekend_warrior': return 'Walk 20k steps in one weekend.';
      case 'circle_champion': return 'Finished top 3 in circle leaderboard.';
      case 'grand_conqueror': return 'Finish #1 in the circle leaderboard.';
      case 'season_legend': return 'Win #1 for 3 seasons.';
      default: return '';
    }
  }

  Widget _buildAnalyticsUpsell(BuildContext context, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPremium ? Colors.teal.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? Colors.teal.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: isPremium ? Colors.teal : Colors.grey,
              ),
              const SizedBox(width: 12),
              const Text(
                'Advanced Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!isPremium)
                const Icon(Icons.lock, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          if (isPremium)
            const Text(
              'Your weekly performance hit an all-time high! You expanded your territory by 12% more than last week.',
              style: TextStyle(color: Colors.teal),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock detailed trends, territory growth heatmaps, and competitive performance insights.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _showPaywall(context),
                    child: const Text('Upgrade to Unlock'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
