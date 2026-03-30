import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_steps/services/health_service.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/services/supabase_service.dart';
import '../widgets/steps_app_bar.dart';
import '../widgets/progress_circle.dart';
import '../widgets/streak_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/territory_preview_card.dart';

class StepsView extends ConsumerWidget {
  const StepsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepState = ref.watch(stepProvider);
    final user = SupabaseService().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepsAppBar(
                userName: user?.email?.split('@')[0] ?? 'User',
                profileImageUrl: null, // Can be integrated with profile later
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressCircle(steps: stepState.steps, goal: 10000),
                    StreakCard(streakDays: stepState.weeklyStreak),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Metrics",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: Color(0xFF0D968B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        MetricCard(
                          label: 'Kcal burned',
                          value: (stepState.steps * 0.04).toStringAsFixed(0),
                          unit: '',
                          icon: Icons.bolt,
                          iconColor: Colors.orange,
                          iconBgColor: const Color(0xFFFFF7ED),
                        ),

                        MetricCard(
                          label: 'Km traveled',
                          value: (stepState.steps * 0.0008).toStringAsFixed(1),
                          unit: '',
                          icon: Icons.route,
                          iconColor: Colors.green,
                          iconBgColor: const Color(0xFFF0FDF4),
                        ),
                        MetricCard(
                          label: 'Min active',
                          value: (stepState.steps * 0.01).toStringAsFixed(0),
                          unit: '',
                          icon: Icons.schedule,
                          iconColor: Colors.blue,
                          iconBgColor: const Color(0xFFEFF6FF),
                        ),
                        MetricCard(
                          label: 'Energy',
                          value: stepState.attackEnergy.toString(),
                          unit: '',
                          icon: Icons.bolt,
                          iconColor: Colors.orange,
                          iconBgColor: const Color(0xFFFFF7ED),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Last Territory",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    Text(
                      "Your most recent walk",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    InkWell(
                      onTap: () {
                        NotificationService.sendTestNotification();
                      },
                      child: const TerritoryPreviewCard(
                        title: 'Greenwich Village Circuit',
                        location: 'Morning Walk',
                        imageUrl:
                            'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?q=80&w=2670&auto=format&fit=crop',
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
