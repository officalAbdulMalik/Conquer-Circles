import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_service.dart';

final circleRaidAlertsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, circleId) {
      return GameService().raidAlertStream(circleId);
    });
