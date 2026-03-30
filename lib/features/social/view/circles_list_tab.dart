import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            }).toList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Create Circle',
            icon: Icons.add_circle_outline,
            onTap: () => _showCreateCircleDialog(context, ref),
            color: const Color(0xFF0D968B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            label: 'Join by Code',
            icon: Icons.qr_code_scanner,
            onTap: () => _showJoinCircleDialog(context, ref),
            color: const Color(0xFF0F172A),
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
          Icon(Icons.group_work_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No circles yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a circle to play with friends\nor join an existing one with a code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard(BuildContext context, dynamic circle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.group, color: Color(0xFF0D968B), size: 30),
        ),
        title: Text(
          circle['name'] ?? 'Untitled Circle',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Code: ${circle['invite_code']}'),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
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
              backgroundColor: const Color(0xFF0D968B),
              foregroundColor: Colors.white,
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
              backgroundColor: const Color(0xFF0D968B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
