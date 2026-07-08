import 'package:flutter/material.dart';

/// A single row from the `energy_ledger` — one change to the player's attack
/// energy (a territory battle spend, a walking/step-milestone gain, etc.).
class EnergyLedgerEntry {
  const EnergyLedgerEntry({
    required this.id,
    required this.delta,
    required this.type,
    required this.description,
    required this.createdAt,
    this.balanceAfter,
    this.metadata = const {},
  });

  final String id;

  /// Signed change to attack energy. Positive = gained, negative = spent.
  final int delta;

  /// Machine type, e.g. `steps`, `step_milestone`, `territory_battle`.
  final String type;

  /// Human-readable label shown in the UI.
  final String description;

  final DateTime createdAt;

  /// Energy balance immediately after this change (null for backfilled rows).
  final int? balanceAfter;

  final Map<String, dynamic> metadata;

  bool get isGain => delta >= 0;

  /// `+60` / `-90` style label.
  String get amountLabel => '${delta >= 0 ? '+' : ''}$delta';

  factory EnergyLedgerEntry.fromMap(Map<String, dynamic> map) {
    return EnergyLedgerEntry(
      id: map['id']?.toString() ?? '',
      delta: (map['delta'] as num?)?.toInt() ?? 0,
      type: map['type']?.toString() ?? 'adjustment',
      description: (map['description']?.toString().trim().isNotEmpty ?? false)
          ? map['description'].toString()
          : _fallbackDescription(map['type']?.toString()),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      balanceAfter: (map['balance_after'] as num?)?.toInt(),
      metadata: (map['metadata'] is Map)
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  static String _fallbackDescription(String? type) {
    switch (type) {
      case 'steps':
        return 'Walking reward';
      case 'step_milestone':
        return 'Step milestone bonus';
      case 'territory_battle':
        return 'Territory battle';
      default:
        return 'Energy activity';
    }
  }
}

/// UI helper: the accent colour used for the amount in the Energy Usage list.
Color energyAmountColor(EnergyLedgerEntry entry) {
  return entry.isGain ? const Color(0xFF5169FF) : const Color(0xFFEF4444);
}
