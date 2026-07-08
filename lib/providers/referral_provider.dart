import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:test_steps/models/referral_summary.dart';
import 'package:test_steps/services/supabase_service.dart';

/// Loads the signed-in user's referral summary (code, total earned, history).
/// Auto-disposes so it refreshes each time the referral screen opens;
/// invalidate it to pull-to-refresh.
final referralSummaryProvider =
    FutureProvider.autoDispose<ReferralSummary>((ref) async {
  return SupabaseService().getReferralSummary();
});
