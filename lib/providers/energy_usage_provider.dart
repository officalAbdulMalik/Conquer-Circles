import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:test_steps/models/energy_ledger_entry.dart';
import 'package:test_steps/services/supabase_service.dart';

/// Bundles the energy history with the current balance for the Energy Usage
/// screen so both load in a single async pass.
class EnergyUsageData {
  const EnergyUsageData({required this.balance, required this.entries});

  final int balance;
  final List<EnergyLedgerEntry> entries;

  bool get isEmpty => entries.isEmpty;
}

/// Fetches the signed-in user's recent energy activity and current balance.
/// Auto-disposes so it re-fetches each time the screen is opened; invalidate
/// it to pull-to-refresh.
final energyUsageProvider =
    FutureProvider.autoDispose<EnergyUsageData>((ref) async {
  final service = SupabaseService();
  final entries = await service.getEnergyHistory(limit: 50);
  final balance = await service.getAttackEnergy();
  return EnergyUsageData(balance: balance, entries: entries);
});
