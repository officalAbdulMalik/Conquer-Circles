import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/game_service.dart';
import '../../subscription/view/premium_paywall_view.dart';

final seasonRecapProvider = FutureProvider.family<Map<String, dynamic>?, int>((
  ref,
  seasonId,
) {
  return GameService().getMySeasonRecap(seasonId);
});

class SeasonRecapView extends ConsumerWidget {
  final int seasonId;
  final String seasonName;

  const SeasonRecapView({
    super.key,
    required this.seasonId,
    required this.seasonName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapData = ref.watch(seasonRecapProvider(seasonId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark
      body: SafeArea(
        child: recapData.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, s) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (recap) {
            final rewardsCount =
                recap?['rewards_unlocked'] ??
                8; // Fallback to 8 as per user doc

            return Column(
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.workspace_premium,
                  size: 80,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Season $seasonName Recap',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _buildStatRow(
                  'Tiles Captured',
                  '${recap?['tiles_captured'] ?? 0}',
                ),
                _buildStatRow('Total Steps', '${recap?['total_steps'] ?? 0}'),
                _buildStatRow('Rewards Earned', '$rewardsCount'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You unlocked $rewardsCount rewards!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unlock premium rewards from this season.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PremiumPaywallView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D968B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Maybe Later'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
