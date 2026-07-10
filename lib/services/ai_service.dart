import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:test_steps/models/dashboard_model.dart';

class AiObjective {
  final String title;
  final String progressLabel;
  final double percent; // 0.0 – 1.0

  const AiObjective({
    required this.title,
    required this.progressLabel,
    required this.percent,
  });

  factory AiObjective.fromJson(Map<String, dynamic> json) => AiObjective(
    title: json['title']?.toString() ?? '',
    progressLabel: json['progressLabel']?.toString() ?? '',
    percent: ((json['percent'] as num?)?.toDouble() ?? 0) / 100,
  );
}

class AiService {
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _endpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  Future<String> generateTerritorySuggestion(DashboardState stats) async {
    final prompt =
        'You are a coach for a fitness territory-capture game where players '
        'walk to claim map tiles. '
        'Player stats: ${stats.steps} steps today, '
        '${stats.distanceKm.toStringAsFixed(1)} km walked, '
        '${stats.attackEnergy}/${stats.attackEnergyCap} energy, '
        '${stats.totalAreaKm2.toStringAsFixed(1)} km² territory owned, '
        'level ${stats.level}, ${stats.weeklyStreak}-day streak. '
        'Write ONE short, specific, game-like territory strategy in max 12 words. '
        'Do not start with "I" or "You". Be motivating and action-oriented.';

    final text = await _chat(prompt, maxTokens: 60);
    return text ?? 'Expand into nearby free territory to grow your zone.';
  }

  Future<List<AiObjective>> generateObjectives(DashboardState stats) async {
    final stepGoal = stats.stepGoal > 0 ? stats.stepGoal : 10000;
    final prompt =
        'Generate exactly 3 personalized fitness game objectives for this player.\n'
        'Stats: ${stats.steps}/$stepGoal steps today, '
        '${stats.distanceKm.toStringAsFixed(1)} km, '
        '${stats.attackEnergy}/${stats.attackEnergyCap} energy, '
        'level ${stats.level}, ${stats.xp}/${stats.xpGoal} XP, '
        '${stats.weeklyStreak}-day streak, '
        '${stats.totalAreaKm2.toStringAsFixed(1)} km² territory, '
        '${stats.calories} kcal burned.\n'
        'Return ONLY a raw JSON array — no markdown, no explanation. '
        'Each element: {"title":"max 7 words","progressLabel":"short progress e.g. 3200/10000 steps","percent":0-100}.\n'
        'Make percent values realistic based on the stats provided.';

    final text = await _chat(prompt, maxTokens: 300);
    if (text == null) return _fallbackObjectives(stats);

    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1) return _fallbackObjectives(stats);
      final list = jsonDecode(text.substring(start, end + 1)) as List;
      return list
          .map((e) => AiObjective.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallbackObjectives(stats);
    }
  }

  Future<String?> _chat(String prompt, {int maxTokens = 200}) async {
    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': maxTokens,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['choices']?[0]?['message']?['content']?.toString().trim();
    } catch (_) {
      return null;
    }
  }

  List<AiObjective> _fallbackObjectives(DashboardState stats) {
    final stepGoal = stats.stepGoal > 0 ? stats.stepGoal : 10000;
    return [
      AiObjective(
        title: 'Hit your daily step goal',
        progressLabel: '${stats.steps} / $stepGoal steps',
        percent: (stats.steps / stepGoal).clamp(0.0, 1.0),
      ),
      AiObjective(
        title: 'Build a 7-day streak',
        progressLabel: '${stats.weeklyStreak} / 7 days',
        percent: (stats.weeklyStreak / 7).clamp(0.0, 1.0),
      ),
      AiObjective(
        title: 'Expand your territory',
        progressLabel: '${stats.totalAreaKm2.toStringAsFixed(1)} km² claimed',
        percent: (stats.totalAreaKm2 / 10).clamp(0.0, 1.0),
      ),
    ];
  }
}
