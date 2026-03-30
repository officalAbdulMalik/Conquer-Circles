import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

final badgeServiceProvider = Provider((ref) => BadgeService());

final unlockedBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return await service.getUnlockedBadges();
});
