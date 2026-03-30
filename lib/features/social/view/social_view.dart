import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/invite_model.dart';
import '../../../providers/invites_provider.dart';
import '../widgets/social_header.dart';
import '../widgets/social_tab_bar.dart';
import '../widgets/user_search_field.dart';
import '../widgets/discover_user_card.dart';
import '../widgets/sent_invite_card.dart';
import '../widgets/user_search_delegate.dart';
import './circles_list_tab.dart';
import '../../../providers/subscription_provider.dart';
import '../../subscription/view/premium_paywall_view.dart';

class SocialView extends ConsumerStatefulWidget {
  const SocialView({super.key});

  @override
  ConsumerState<SocialView> createState() => _SocialViewState();
}

class _SocialViewState extends ConsumerState<SocialView> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: UserSearchDelegate(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(invitesProvider);
    final pendingCount = inviteState.pendingCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SocialHeader(
              onMenuPressed: () {},
              onNotificationsPressed: () => setState(() => _selectedTab = 1),
              onSearchPressed: _openSearch,
              hasUnreadNotifications: pendingCount > 0,
            ),
            SocialTabBar(
              selectedIndex: _selectedTab,
              onTabSelected: (index) => setState(() => _selectedTab = index),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? _buildDiscoverTab(inviteState)
                  : _selectedTab == 1
                      ? _buildCirclesTab()
                      : _buildNotificationsTab(inviteState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab(InvitesState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserSearchField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(invitesProvider.notifier).searchUsers(value);
            },
          ),
          if (state.searchResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Search Results',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: state.searchResults.map((user) {
                  return DiscoverUserCard(
                    name: user.username,
                    level: '1', // Default level if not in model
                    avatarUrl: null, // Profiles might not have avatarUrl yet
                    onInvitePressed: () {
                      final subState = ref.read(subscriptionProvider);
                      if (!subState.hasUnlimitedInvites && state.sentInvites.length >= subState.maxFreeInvites) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumPaywallView(),
                          ),
                        );
                        return;
                      }
                      ref.read(invitesProvider.notifier).sendInvite(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invite sent to ${user.username}'),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
          if (state.sentInvites.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Sent Invites',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: state.sentInvites.map((invite) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SentInviteCard(
                        name: invite.inviteeUsername ?? 'User',
                        status: invite.status,
                        avatarUrl: null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(InvitesState state) {
    if (state.receivedInvites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: state.receivedInvites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final invite = state.receivedInvites[index];
        return _buildInviteNotification(invite);
      },
    );
  }

  Widget _buildInviteNotification(Invite invite) {
    final bool isActioned = invite.status != 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActioned
            ? Colors.white
            : const Color(0xFFEFF6FF).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActioned ? const Color(0xFFF1F5F9) : const Color(0xFFDBEAFE),
        ),
        boxShadow: [
          if (!isActioned)
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: invite.inviterUsername ?? 'Someone',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: ' invited you to join their territory game.',
                          ),
                        ],
                      ),
                    ),
                    if (isActioned) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${invite.status.toUpperCase()}',
                        style: TextStyle(
                          color: invite.status == 'accepted'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isActioned)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (!isActioned) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(invitesProvider.notifier)
                          .acceptInvite(invite.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(invitesProvider.notifier)
                          .rejectInvite(invite.id);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCirclesTab() {
    return const CirclesListTab();
  }
}
