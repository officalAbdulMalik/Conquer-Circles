import 'package:test_steps/features/social/models/raid_models.dart';
import 'package:test_steps/core/constants/app_emojis.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample raid alerts data
// ─────────────────────────────────────────────────────────────────────────────

final List<RaidAlert> sampleRaidAlerts = [
  RaidAlert(
    attacker: 'DarkCircle',
    target: 'South Shore',
    status: RaidStatus.activeAttack,
    timeAgo: '2m ago',
    iconEmoji: AppEmojis.swords,
  ),
  RaidAlert(
    attacker: 'StormPack',
    target: 'East Heights',
    status: RaidStatus.repelled,
    timeAgo: '14m ago',
    iconEmoji: AppEmojis.shield,
  ),
  RaidAlert(
    attacker: 'VoidRunners',
    target: 'West Harbor',
    status: RaidStatus.zoneLost,
    timeAgo: '1h ago',
    iconEmoji: AppEmojis.dead,
  ),
];