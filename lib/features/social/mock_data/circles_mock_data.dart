import 'package:flutter/material.dart';
import 'package:test_steps/features/social/models/circle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample circles data
// ─────────────────────────────────────────────────────────────────────────────

final List<CircleData> sampleCircles = [
  CircleData(
    name: 'IronVault', quote: '"No territory falls on our watch."',
    logoEmoji: '🛡️', logoBgColor: const Color(0xFFD4F5E2),
    cardBgColor: const Color(0xFFEDFDF4),
    rank: 2, rankTrend: 0,
    members: 22, maxMembers: 24, zones: 28, wins: 39, xp: '261k',
    tags: const [
      CircleTag(label: 'Defensive',   color: Color(0xFF22C55E)),
      CircleTag(label: 'Invite Only', color: Color(0xFFF59E0B), icon: '🔒'),
      CircleTag(label: 'Lv 15+',      color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['🏆', '🦅', '💀'],
    joinStatus: JoinStatus.request,
    joinColor: const Color(0xFF22C55E),
    badge: '🔥 Hot', badgeColor: const Color(0xFFEF4444),
  ),
  CircleData(
    name: 'NeonStrike', quote: '"Neon streets, neon dreams."',
    logoEmoji: '💜', logoBgColor: const Color(0xFFF3E8FF),
    cardBgColor: const Color(0xFFFAF4FF),
    rank: 3, rankTrend: 1,
    members: 14, maxMembers: 20, zones: 22, wins: 31, xp: '198k',
    tags: const [
      CircleTag(label: 'Balanced', color: Color(0xFF6C5CE7)),
      CircleTag(label: 'Open',     color: Color(0xFF22C55E), icon: '👥'),
      CircleTag(label: 'Lv 8+',   color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['💜', '🌙', '⚡'],
    joinStatus: JoinStatus.join,
    joinColor: const Color(0xFF6C5CE7),
  ),
  CircleData(
    name: 'VoltRunners', quote: '"Speed is the only strategy."',
    logoEmoji: '⚡', logoBgColor: const Color(0xFFFEF9C3),
    cardBgColor: const Color(0xFFFFFBEB),
    rank: 5, rankTrend: 1,
    members: 19, maxMembers: 24, zones: 18, wins: 25, xp: '175k',
    tags: const [
      CircleTag(label: 'Aggressive', color: Color(0xFFEF4444)),
      CircleTag(label: 'Open',       color: Color(0xFF22C55E), icon: '👥'),
      CircleTag(label: 'Lv 10+',    color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['⚡', '🦊', '🐺'],
    joinStatus: JoinStatus.join,
    joinColor: const Color(0xFFF59E0B),
  ),
  CircleData(
    name: 'TerraGuard', quote: '"We grow, we guard, we conquer."',
    logoEmoji: '🌿', logoBgColor: const Color(0xFFD1FAE5),
    cardBgColor: const Color(0xFFF0FDF4),
    rank: 8, rankTrend: -1,
    members: 16, maxMembers: 20, zones: 15, wins: 18, xp: '142k',
    tags: const [
      CircleTag(label: 'Casual', color: Color(0xFF06B6D4)),
      CircleTag(label: 'Open',   color: Color(0xFF22C55E), icon: '👥'),
      CircleTag(label: 'Lv 5+', color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['🌿', '🐢', '🌱'],
    joinStatus: JoinStatus.join,
    joinColor: const Color(0xFF10B981),
    badge: 'New', badgeColor: const Color(0xFF10B981),
  ),
  CircleData(
    name: 'DarkCircle', quote: '"Your fear fuels our steps."',
    logoEmoji: '💀', logoBgColor: const Color(0xFFE5E7EB),
    cardBgColor: const Color(0xFFF9FAFB),
    rank: 4, rankTrend: -1,
    members: 24, maxMembers: 24, zones: 26, wins: 42, xp: '220k',
    tags: const [
      CircleTag(label: 'Aggressive', color: Color(0xFFEF4444)),
      CircleTag(label: 'Full',       color: Color(0xFF9A9AB0), icon: '⭕'),
      CircleTag(label: 'Lv 20+',    color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['💀', '⚡', '✨'],
    joinStatus: JoinStatus.full,
    joinColor: const Color(0xFF9A9AB0),
  ),
  CircleData(
    name: 'WaveWalkers', quote: '"Ride the wave, own the coast."',
    logoEmoji: '🏄', logoBgColor: const Color(0xFFBAE6FD),
    cardBgColor: const Color(0xFFF0F9FF),
    rank: 9, rankTrend: 1,
    members: 11, maxMembers: 20, zones: 12, wins: 14, xp: '118k',
    tags: const [
      CircleTag(label: 'Casual', color: Color(0xFF06B6D4)),
      CircleTag(label: 'Open',   color: Color(0xFF22C55E), icon: '👥'),
      CircleTag(label: 'Lv 3+', color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['🏄', '🐬', '🌊'],
    joinStatus: JoinStatus.join,
    joinColor: const Color(0xFF0EA5E9),
    badge: 'New', badgeColor: const Color(0xFF10B981),
  ),
  CircleData(
    name: 'BlazePack', quote: '"Burn every zone we touch."',
    logoEmoji: '🔥', logoBgColor: const Color(0xFFFFE4E6),
    cardBgColor: const Color(0xFFFFF5F5),
    rank: 6, rankTrend: 0,
    members: 20, maxMembers: 24, zones: 20, wins: 33, xp: '164k',
    tags: const [
      CircleTag(label: 'Aggressive',  color: Color(0xFFEF4444)),
      CircleTag(label: 'Invite Only', color: Color(0xFFF59E0B), icon: '🔒'),
      CircleTag(label: 'Lv 12+',     color: Color(0xFF8A8AA8), icon: '☆'),
    ],
    memberEmojis: ['🔥', '⚠️', '😈'],
    joinStatus: JoinStatus.request,
    joinColor: const Color(0xFFEF4444),
  ),
];