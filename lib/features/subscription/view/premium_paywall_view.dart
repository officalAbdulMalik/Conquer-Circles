import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/subscription_service.dart';

final offeringsProvider = FutureProvider<Offerings?>((ref) {
  return SubscriptionService().getOfferings();
});

class PremiumPaywallView extends ConsumerWidget {
  const PremiumPaywallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      body: offeringsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(
          child: Text(
            'Error loading offers',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (offerings) {
          final currentOffering = offerings?.current;
          final premiumPackage = currentOffering?.availablePackages.firstWhere(
            (p) => p.packageType == PackageType.monthly,
            orElse: () => currentOffering.availablePackages.first,
          );
          final seasonPackage = currentOffering?.availablePackages.firstWhere(
            (p) => p.identifier.contains('season'),
            orElse: () => currentOffering.availablePackages.last,
          );

          return Stack(
            children: [
              // Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                      Color(0xFF0D9488),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildMainBenefits(),
                            const SizedBox(height: 32),
                            _buildComparisonTable(),
                            const SizedBox(height: 32),
                            _buildPricingOptions(
                              context,
                              ref,
                              premiumPackage,
                              seasonPackage,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            'GO PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainBenefits() {
    return Column(
      children: [
        const Icon(Icons.auto_awesome, size: 60, color: Color(0xFFFFD700)),
        const SizedBox(height: 16),
        const Text(
          'Unlock the Full Experience',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Elevate your gameplay and support the community.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildComparisonRow('Max Circles', '1', '5'),
          const Divider(color: Colors.white12),
          _buildComparisonRow('Daily Invites', '3', 'Unlimited'),
          const Divider(color: Colors.white12),
          _buildComparisonRow('Energy Cap', '400', '600'),
          const Divider(color: Colors.white12),
          _buildComparisonRow('Season Rewards', 'Basic', 'Premium'),
          const Divider(color: Colors.white12),
          _buildComparisonRow('Advanced Analytics', '❌', '✅'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String free, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptions(
    BuildContext context,
    WidgetRef ref,
    Package? premium,
    Package? season,
  ) {
    return Column(
      children: [
        if (premium != null)
          _PricingCard(
            title: 'Premium Subscription',
            price: premium.storeProduct.priceString,
            period: 'per month',
            description: premium.storeProduct.description,
            icon: Icons.star,
            isPopular: true,
            onTap: () async {
              final success = await ref
                  .read(subscriptionProvider.notifier)
                  .purchasePackage(premium);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Welcome to Premium! 💎')),
                );
              }
            },
          ),
        const SizedBox(height: 16),
        if (season != null)
          _PricingCard(
            title: 'Season Pass',
            price: season.storeProduct.priceString,
            period: 'for current season',
            description: season.storeProduct.description,
            icon: Icons.confirmation_number,
            isPopular: false,
            color: const Color(0xFF0D968B),
            onTap: () async {
              final success = await ref
                  .read(subscriptionProvider.notifier)
                  .purchasePackage(season);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Season Pass Activated! 🎟️')),
                );
              }
            },
          ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final IconData icon;
  final bool isPopular;
  final Color? color;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.icon,
    this.isPopular = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: isPopular
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  period,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
