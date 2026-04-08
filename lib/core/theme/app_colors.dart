import 'package:flutter/material.dart';

class AppColors {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color brandPrimary = Color(0xFF0D9488); // Teal
  static const Color brandPrimaryDark = Color(0xFF0F766E);
  static const Color brandSecondary = Color(0xFFFACC15); // Yellow
  static const Color brandAccent = Color(0xFF6366F1); // Indigo
  static const Color brandPurple = Color(0xFF675FAA);
  static const Color brandCyan = Color(0xFF53E4F3);
  static const Color brandLightCyan = Color(0xFF99D7E9);

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF8A8AA0);
  static const Color textNavy = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFFCCCCCC);
  static const Color textLight = Color(0xFF99A1AF);

  // ── Background & Surface ─────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF251B56);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bgSoftPurple = Color(0xFFF0EEFF);
  static const Color bgProgress = Color(0xFFEEEEF5);

  // ── Semantic / Status Colors ──────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Functional / Leaderboard / Awards ────────────────────────────────────
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color accentIndigo = Color(0xFF5B4FE8);
  static const Color tabActiveBg = Color(0xFFEEECFF);

  // ── Chat specific colors ───────────────────────────────────────────────────
  static const Color bubbleMe = Color(0xFF7C6FF7);
  static const Color bubbleOther = Color(0xFFF4F4FA);
  static const Color inputBg = Color(0xFFF5F5FB);

  // ── Compatibility Mapping (to be used by Theme/Styles) ───────────────────
  static const Color backgroundLight = bgLight;
  static const Color backgroundDark = bgDark;
  static const Color surfaceLight = surface;
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryLight = textNavy;
  static const Color textSecondaryLight = textSecondary;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color cardLight = surface;

  static const Color fillColor = Color(0xffF5F3FF);


   // Background
  static const Color scaffoldBg = Color(0xFFF0F0F8);
  static const Color appBarBg = Colors.white;
  static const Color inputBarBg = Colors.white;
 
  // Bubbles
  static const Color sentBubble = Color(0xFF7C6FCD);
  static const Color receivedBubble = Colors.white;
  static const Color systemBubble = Color(0xFFE8F5E9);
  static const Color xpBubble = Color(0xFFF0FFF4);
 
  // Text
  static const Color sentText = Colors.white;
  static const Color receivedText = Color(0xFF1A1A2E);
  static const Color systemText = Color(0xFF2E7D32);
  static const Color timeText = Color(0xFFAAAAAA);
  static const Color senderIronStrider = Color(0xFFE87040);
  static const Color senderNeonPath = Color(0xFF4CAF50);
 
  // Accents
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color xpGold = Color(0xFFFFB300);
  static const Color purple = Color(0xFF7C6FCD);
  static const Color reactionBg = Color(0xFFF5F5FF);
  static const Color reactionBorder = Color(0xFFE0DEFF);
 
  // Raid
  static const Color raidBubble = Color(0xFFE8F5E9);
  static const Color raidBorder = Color(0xFF81C784);

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFE9D5FF);
  static const Color primaryLighter = Color(0xFFF3EEFF);
  static const Color background = Color(0xFFF0EEFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF10B981);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color orange = Color(0xFFF97316);
  static const Color blue = Color(0xFF3B82F6);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color tileOwned = Color(0xFFD8B4FE);
  static const Color tileContested = Color(0xFFFDE68A);
  static const Color tileNeutral = Color(0xFFE5E7EB);
  static const Color online = Color(0xFF10B981);


 static Gradient  primaryGradient =  LinearGradient(
        colors: [Color(0xff675FAA), Color(0xff675FAA).withAlpha(0x80)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
