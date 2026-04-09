import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_button.dart';
import '../../../providers/circles_provider.dart';
import './circle_detail_view.dart';
import '../../subscription/view/premium_paywall_view.dart';

class CirclesListTab extends ConsumerWidget {
  const CirclesListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circlesState = ref.watch(circlesProvider);

    if (circlesState.isLoading && circlesState.circles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(circlesProvider.notifier).refreshCircles(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildActionButtons(context, ref),
          const SizedBox(height: 24),
          if (circlesState.circles.isEmpty)
            _buildEmptyState()
          else
            ...circlesState.circles.map((circleData) {
              final circle = circleData['circles'];
              return _buildCircleCard(context, circle);
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: AppActionTileButton(
            label: 'Create Circle',
            icon: Icons.add_circle_outline,
            onTap: () => _showCreateCircleDialog(context, ref),
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppActionTileButton(
            label: 'Join by Code',
            icon: Icons.qr_code_scanner,
            onTap: () => _showJoinCircleDialog(context, ref),
            color: AppColors.bgDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.group_work_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.32),
          ),
          const SizedBox(height: 16),
          Text(
            'No circles yet',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a circle to play with friends\nor join an existing one with a code.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard(BuildContext context, dynamic circle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.group, color: AppColors.brandPrimary, size: 30),
        ),
        title: Text(
          circle['name'] ?? 'Untitled Circle',
          style: AppTextStyles.cardTitle,
        ),
        subtitle: Text(
          'Code: ${circle['invite_code']}',
          style: AppTextStyles.cardSubtitle,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CircleDetailView(circleId: circle['id']),
            ),
          );
        },
      ),
    );
  }

  void _showCreateCircleDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Circle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Circle Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final res = await ref
                    .read(circlesProvider.notifier)
                    .createCircle(controller.text, ref);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (res['success'] != true) {
                    if (res['error'].toString().contains('limit reached')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PremiumPaywallView(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${res['error']}')),
                      );
                    }
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinCircleDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Circle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Invite Code (8 chars)',
            border: OutlineInputBorder(),
          ),
          maxLength: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 8) {
                final res = await ref
                    .read(circlesProvider.notifier)
                    .joinCircleByCode(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (res['success'] != true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${res['error']}')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
