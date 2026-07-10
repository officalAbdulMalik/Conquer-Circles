import 'package:riverpod/legacy.dart';

/// Index of the "Profile" tab in [MainNavigation]'s bottom nav — the last tab.
const kProfileTabIndex = 4;

/// Currently selected tab index in the main bottom navigation shell.
/// Exposed as a provider (rather than local widget state) so screens nested
/// inside the shell's IndexedStack — e.g. the profile icon in a header —
/// can switch tabs in place without pushing a second navigation shell.
final mainNavTabIndexProvider = StateProvider<int>((ref) => 0);
