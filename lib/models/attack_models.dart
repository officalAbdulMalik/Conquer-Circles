import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlayerEnergy {
  final int attackEnergy;
  final int energyEarnedToday;
  final int stepsToday;
  final int dailyCap;
  final bool isPremium;

  PlayerEnergy({
    required this.attackEnergy,
    required this.energyEarnedToday,
    required this.stepsToday,
    required this.dailyCap,
    required this.isPremium,
  });

  factory PlayerEnergy.fromJson(Map<String, dynamic> json) {
    return PlayerEnergy(
      attackEnergy: json['attack_energy'] ?? 0,
      energyEarnedToday: json['energy_earned_today'] ?? 0,
      stepsToday: json['steps_today'] ?? 0,
      dailyCap: json['daily_cap'] ?? 400,
      isPremium: json['is_premium'] ?? false,
    );
  }
}

class AttackResult {
  final String result; // 'CAPTURED' or 'DAMAGED'
  final int attackPowerUsed;
  final int territoryEnergyBefore;
  final int territoryEnergyAfter;
  final String? previousOwnerId;
  final String newOwnerId;
  final DateTime cooldownExpires;
  final int playerEnergyRemaining;

  AttackResult({
    required this.result,
    required this.attackPowerUsed,
    required this.territoryEnergyBefore,
    required this.territoryEnergyAfter,
    this.previousOwnerId,
    required this.newOwnerId,
    required this.cooldownExpires,
    required this.playerEnergyRemaining,
  });

  factory AttackResult.fromJson(Map<String, dynamic> json) {
    return AttackResult(
      result: json['result'] ?? 'DAMAGED',
      attackPowerUsed: json['attack_power_used'] ?? 0,
      territoryEnergyBefore: json['territory_energy_before'] ?? 0,
      territoryEnergyAfter: json['territory_energy_after'] ?? 0,
      previousOwnerId: json['previous_owner_id'],
      newOwnerId: json['new_owner_id'] ?? '',
      cooldownExpires: DateTime.parse(json['cooldown_expires']),
      playerEnergyRemaining: json['player_energy_remaining'] ?? 0,
    );
  }

  bool get isCaptured => result == 'CAPTURED';
}

class TerritoryAttackDetails {
  final String territoryId;
  final int gridX;
  final int gridY;
  final int energy;
  final String? ownerId;
  final String? ownerUsername;
  final bool isOwn;
  final bool canAttack;
  final DateTime? cooldownExpires;
  final DateTime? capturedAt;

  TerritoryAttackDetails({
    required this.territoryId,
    required this.gridX,
    required this.gridY,
    required this.energy,
    this.ownerId,
    this.ownerUsername,
    required this.isOwn,
    required this.canAttack,
    this.cooldownExpires,
    this.capturedAt,
  });

  factory TerritoryAttackDetails.fromJson(Map<String, dynamic> json) {
    return TerritoryAttackDetails(
      territoryId: json['territory_id'] ?? '',
      gridX: json['grid_x'] ?? 0,
      gridY: json['grid_y'] ?? 0,
      energy: json['energy'] ?? 0,
      ownerId: json['owner_id'],
      ownerUsername: json['owner_username'],
      isOwn: json['is_own'] ?? false,
      canAttack: json['can_attack'] ?? false,
      cooldownExpires: json['cooldown_expires'] != null
          ? DateTime.parse(json['cooldown_expires'])
          : null,
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'])
          : null,
    );
  }
}
