import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_selector.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _selectedTheme = 'Light';
  bool _dailyAlerts = true;
  bool _reminders = false;
  String _units = 'Metric';

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SettingsHeader(title: 'Settings'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            SettingsSection(
              title: 'Account',
              children: [
                SettingsTile(
                  title: user?.email?.split('@')[0] ?? 'User',
                  subtitle: user?.email ?? '',
                  icon: Icons.person_outline,
                  onTap: () {},
                ),
                SettingsTile(
                  title: 'Password',
                  subtitle: 'Last changed 3 months ago',
                  icon: Icons.lock_outline,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Push Notifications',
              children: [
                SettingsTile(
                  title: 'Daily Alerts',
                  subtitle: 'Get notified about territory challenges',
                  trailing: _buildSwitch(
                    _dailyAlerts,
                    (v) => setState(() => _dailyAlerts = v),
                  ),
                ),
                SettingsTile(
                  title: 'Reminders',
                  subtitle: 'Walk reminders based on your goal',
                  trailing: _buildSwitch(
                    _reminders,
                    (v) => setState(() => _reminders = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Theme Mode',
              children: [
                // ThemeSelector(
                //   selectedMode: _selectedTheme,
                //   onModeSelected: (mode) =>
                //       setState(() => _selectedTheme = mode),
                // ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDangerZone(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF0D9488),
    );
  }

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFF1F5F9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
