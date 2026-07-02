import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

final badgeServiceProvider = Provider((ref) => BadgeService());

final unlockedBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return await service.getUnlockedBadges();
});

/// Every badge from the Supabase `badges` table, with `unlockedAt` set for
/// badges the user has claimed (tracked in `profiles.badges`). Unclaimed
/// badges render with a lock icon.
///
/// Loaded ONCE: the service caches to local storage after the first fetch,
/// and this provider is kept alive so switching tabs never re-triggers a
/// network call. Use `ref.invalidate(allBadgesProvider)` +
/// `getAllBadges(forceRefresh: true)` if a manual refresh is ever needed.
final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return await service.getAllBadges();
});
