
enum BadgeCategory { steps, territory, raids, social, special }

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String icon; // Path or emoji
  final BadgeCategory category;
  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['badge_id'] as String,
      title: getTitle(json['badge_id'] as String),
      description: _getDescription(json['badge_id'] as String),
      icon: _getIcon(json['badge_id'] as String),
      category: _getCategory(json['badge_id'] as String),
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at'] as String) 
          : null,
    );
  }

  static String getTitle(String id) {
    switch (id) {
      case 'step_rookie': return '1 Step Rookie';
      case 'daily_grinder': return '2 Daily Grinder';
      case 'marathon_walker': return '3 Marathon Walker';
      case 'territory_pioneer': return '4 Territory Pioneer';
      case 'territory_builder': return '5 Territory Builder';
      case 'expansion_master': return '6 Expansion Master';
      case 'raid_initiator': return '7 Raid Initiator';
      case 'raid_champion': return '8 Raid Champion';
      case 'raid_destroyer': return '9 Raid Destroyer';
      case 'defense_architect': return '10 Defense Architect';
      case 'fortress_master': return '11 Fortress Master';
      case 'cluster_creator': return '12 Cluster Creator';
      case 'territory_emperor': return '13 Territory Emperor';
      case 'comeback_king': return '14 Comeback King';
      case 'early_bird': return '15 Early Bird';
      case 'night_walker': return '16 Night Walker';
      case 'consistency_hero': return '17 Consistency Hero';
      case 'energy_hoarder': return '18 Energy Hoarder';
      case 'war_hero': return '19 War Hero';
      case 'expansion_legend': return '20 Expansion Legend';
      case 'defender': return '21 Defender';
      case 'rival_slayer': return '22 Rival Slayer';
      case 'territory_guardian': return '23 Territory Guardian';
      case 'park_explorer': return '24 Park Explorer';
      case 'street_king': return '25 Street King';
      case 'strategic_raider': return '26 Strategic Raider';
      case 'weekend_warrior': return '27 Weekend Warrior';
      case 'circle_champion': return '28 Circle Champion';
      case 'grand_conqueror': return '29 Grand Conqueror';
      case 'season_legend': return '30 Season Legend';
      default: return 'Unknown Badge';
    }
  }

  static String _getDescription(String id) {
    switch (id) {
      case 'step_rookie': return 'Walk 5,000 steps in one day.';
      case 'daily_grinder': return 'Walk 10,000 steps for 5 days in a row.';
      case 'marathon_walker': return 'Walk 42 km total in a season.';
      case 'territory_pioneer': return 'Capture 10 tiles.';
      case 'territory_builder': return 'Capture 50 tiles.';
      case 'expansion_master': return 'Capture 100 tiles.';
      case 'raid_initiator': return 'Launch first territory attack.';
      case 'raid_champion': return 'Win 10 raids.';
      case 'raid_destroyer': return 'Win 25 raids.';
      case 'defense_architect': return 'Upgrade 10 tiles to max energy.';
      case 'fortress_master': return 'Hold a tile with 60 energy.';
      case 'cluster_creator': return 'Create a cluster of 7 tiles.';
      case 'territory_emperor': return 'Control 25 tiles simultaneously.';
      case 'comeback_king': return 'Lose territory then reclaim it within 24 hours.';
      case 'early_bird': return 'Walk before 7 AM for 7 days.';
      case 'night_walker': return 'Walk after 10 PM for 5 days.';
      case 'consistency_hero': return 'Walk every day for 14 days.';
      case 'energy_hoarder': return 'Store maximum attack energy.';
      case 'war_hero': return 'Win 15 raids in war phase.';
      case 'expansion_legend': return 'Capture 10 new tiles in one day.';
      case 'defender': return 'Successfully defend tile 10 times.';
      case 'rival_slayer': return 'Capture territory from same rival 5 times.';
      case 'territory_guardian': return 'Hold territory for entire season.';
      case 'park_explorer': return 'Capture 5 park tiles.';
      case 'street_king': return 'Control an entire street cluster.';
      case 'strategic_raider': return 'Capture tile with exactly equal energy.';
      case 'weekend_warrior': return 'Walk 20k steps in one weekend.';
      case 'circle_champion': return 'Finished top 3 in circle leaderboard.';
      case 'grand_conqueror': return 'Finish #1 in the circle leaderboard.';
      case 'season_legend': return 'Win #1 for 3 seasons.';
      default: return 'A mysterious achievement.';
    }
  }

  static String _getIcon(String id) {
    // For now, return emojis as placeholders. In future, return asset paths.
    switch (id) {
      case 'step_rookie': return '👟';
      case 'daily_grinder': return '🔥';
      case 'marathon_walker': return '🏁';
      case 'territory_pioneer': return '🚩';
      case 'territory_builder': return '🧱';
      case 'expansion_master': return '👑';
      case 'raid_initiator': return '⚔️';
      case 'raid_champion': return '🏆';
      case 'raid_destroyer': return '💥';
      case 'defense_architect': return '🏗️';
      case 'fortress_master': return '🏰';
      case 'cluster_creator': return '💠';
      case 'territory_emperor': return '🌎';
      case 'comeback_king': return '🔄';
      case 'early_bird': return '🌅';
      case 'night_walker': return '🌙';
      case 'consistency_hero': return '📅';
      case 'energy_hoarder': return '🔋';
      case 'war_hero': return '🎖️';
      case 'expansion_legend': return '📈';
      case 'defender': return '🛡️';
      case 'rival_slayer': return '🎯';
      case 'territory_guardian': return '💂';
      case 'park_explorer': return '🌳';
      case 'street_king': return '🛣️';
      case 'strategic_raider': return '🧠';
      case 'weekend_warrior': return '⚡';
      case 'circle_champion': return '🥇';
      case 'grand_conqueror': return '💎';
      case 'season_legend': return '🌟';
      default: return '❓';
    }
  }

  static BadgeCategory _getCategory(String id) {
    if (id.contains('step') || id.contains('walker') || id.contains('grinder') || id.contains('consistency') || id.contains('early') || id.contains('night') || id.contains('weekend')) {
      return BadgeCategory.steps;
    }
    if (id.contains('territory') || id.contains('expansion') || id.contains('cluster') || id.contains('street') || id.contains('park')) {
      return BadgeCategory.territory;
    }
    if (id.contains('raid') || id.contains('war') || id.contains('rival') || id.contains('strategic')) {
      return BadgeCategory.raids;
    }
    if (id.contains('defense') || id.contains('fortress') || id.contains('defender') || id.contains('guardian')) {
      return BadgeCategory.raids; // or defense
    }
    return BadgeCategory.special;
  }

  static const List<String> allBadgeIds = [
    'step_rookie', 'daily_grinder', 'marathon_walker',
    'territory_pioneer', 'territory_builder', 'expansion_master',
    'raid_initiator', 'raid_champion', 'raid_destroyer',
    'defense_architect', 'fortress_master', 'cluster_creator',
    'territory_emperor', 'comeback_king', 'early_bird',
    'night_walker', 'consistency_hero', 'energy_hoarder',
    'war_hero', 'expansion_legend', 'defender',
    'rival_slayer', 'territory_guardian', 'park_explorer',
    'street_king', 'strategic_raider', 'weekend_warrior',
    'circle_champion', 'grand_conqueror', 'season_legend',
  ];
}
