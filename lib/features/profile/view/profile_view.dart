import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/features/profile/view/edit_profile_view.dart';
import 'package:test_steps/features/profile/widgets/profile_content.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username']?.toString();

    return ProfileContent(
      username: (username != null && username.isNotEmpty)
          ? username
          : 'FitWarrior_92',
      handle: '@fitwarrior · Joined Jan 2024',
      onEditProfile: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditProfileView()),
        );
      },
      onLogout: () async {
        await Supabase.instance.client.auth.signOut();
      },
    );
  }
}
