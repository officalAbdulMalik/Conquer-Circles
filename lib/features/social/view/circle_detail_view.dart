import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/circles_provider.dart';
import './circle_comms_view.dart';

class CircleDetailView extends ConsumerStatefulWidget {
  final String circleId;
  const CircleDetailView({super.key, required this.circleId});

  @override
  ConsumerState<CircleDetailView> createState() => _CircleDetailViewState();
}

class _CircleDetailViewState extends ConsumerState<CircleDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);
    final circleData = circlesState.circles.firstWhere(
      (c) => c['circles']['id'] == widget.circleId,
      orElse: () => {},
    );

    if (circleData.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Circle not found')),
      );
    }

    final circle = circleData['circles'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(circle['name'] ?? 'Circle Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CircleCommsView(
                    circleId: widget.circleId,
                    circleName: circle['name'],
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveConfirm(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Text(
                  'Leave Circle',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Leaderboard'),
          ],
          labelColor: const Color(0xFF0D968B),
          indicatorColor: const Color(0xFF0D968B),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(widget.circleId),
          _buildLeaderboardTab(widget.circleId),
        ],
      ),
    );
  }

  Widget _buildMembersTab(String circleId) {
    // In a real app, we'd fetch members properly. For now, we'll use a FutureProvider
    // but GameService.getCircleWithMembers is available.
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref
          .read(circlesProvider.notifier)
          .gameService
          .getCircleWithMembers(circleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final members = data['members'] as List;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final profile = member['profiles'];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.person, color: Color(0xFF0D968B)),
              ),
              title: Text('User'),
              subtitle: Text(member['role'] ?? 'Member'),
              trailing: Text('0 Tiles'),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTab(String circleId) {
    final lbAsync = ref.watch(circleLeaderboardProvider(circleId));

    return lbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (members) {
        if (members.isEmpty)
          return const Center(child: Text('No stats for this season yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index];
            return ListTile(
              leading: Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text(m['username'] ?? 'User'),
              trailing: Text(
                '${m['tiles_owned']} Tiles',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D968B),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLeaveConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Circle?'),
        content: const Text(
          'You will no longer receive raid alerts for this circle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(circlesProvider.notifier).leaveCircle(widget.circleId);
              Navigator.pop(context); // dialog
              Navigator.pop(context); // detail view
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
