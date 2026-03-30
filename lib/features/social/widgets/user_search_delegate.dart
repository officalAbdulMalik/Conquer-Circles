import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_steps/services/supabase_service.dart';
import '../../../providers/invites_provider.dart';
import '../widgets/discover_user_card.dart';

class UserSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  UserSearchDelegate({required this.ref});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
        onPressed: () {
          query = '';
          Future.microtask(() {
            ref.read(invitesProvider.notifier).searchAllUsers('');
          });
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length >= 2) {
      Future.microtask(() {
        ref.read(invitesProvider.notifier).searchAllUsers(query);
      });
    }
    return _buildSearchList();
  }

  Widget _buildSearchList() {
    final state = ref.watch(invitesProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D968B)),
      );
    }

    if (state.searchResults.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found matching "$query"',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final user = state.searchResults[index];
        final isMe = user.id == SupabaseService().currentUser?.id;

        return DiscoverUserCard(
          name: isMe ? '${user.username} (You)' : user.username,
          level: '1',
          onInvitePressed: isMe
              ? null
              : () {
                  ref.read(invitesProvider.notifier).sendInvite(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invite sent to ${user.username}')),
                  );
                },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        border: InputBorder.none,
      ),
    );
  }
}
