/// The signed-in user's referral overview, returned by `get_referral_summary`.
class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.totalEarned,
    required this.history,
  });

  /// The user's own shareable referral code.
  final String code;

  /// Total energy earned from all successful referrals.
  final int totalEarned;

  final List<ReferralEvent> history;

  factory ReferralSummary.fromMap(Map<String, dynamic> map) {
    final rawHistory = map['history'];
    final history = (rawHistory is List)
        ? rawHistory
              .whereType<Map>()
              .map((e) => ReferralEvent.fromMap(Map<String, dynamic>.from(e)))
              .toList()
        : <ReferralEvent>[];
    return ReferralSummary(
      code: map['code']?.toString() ?? '',
      totalEarned: (map['total_earned'] as num?)?.toInt() ?? 0,
      history: history,
    );
  }

  static const empty = ReferralSummary(code: '', totalEarned: 0, history: []);
}

/// A single successful referral (someone signed up with the user's code).
class ReferralEvent {
  const ReferralEvent({
    required this.name,
    required this.energy,
    required this.createdAt,
  });

  final String name;
  final int energy;
  final DateTime createdAt;

  String get energyLabel => '+$energy';

  factory ReferralEvent.fromMap(Map<String, dynamic> map) {
    return ReferralEvent(
      name: (map['name']?.toString().trim().isNotEmpty ?? false)
          ? map['name'].toString()
          : 'New member',
      energy: (map['energy'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
