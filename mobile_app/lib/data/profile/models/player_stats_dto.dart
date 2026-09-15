import 'package:kelime_analiz_mobile/domain/profile/models/player_stats.dart';

class PlayerStatsDto {
  const PlayerStatsDto._();

  static PlayerStats fromMap(Map<String, dynamic>? data) => PlayerStats(
    totalGames: data?['totalGames'] as int? ?? 0,
    wins: data?['wins'] as int? ?? 0,
    losses: data?['losses'] as int? ?? 0,
    draws: data?['draws'] as int? ?? 0,
    totalScore: data?['totalScore'] as int? ?? 0,
    totalPlaySeconds: data?['totalPlaySeconds'] as int? ?? 0,
    weeklyScore: data?['weeklyScore'] as int? ?? 0,
    xp: data?['xp'] as int? ?? 0,
    analysisAccuracyTotal:
        (data?['analysisAccuracyTotal'] as num?)?.toDouble() ?? 0,
    analyzedGames: data?['analyzedGames'] as int? ?? 0,
    winStreak: data?['winStreak'] as int? ?? 0,
    bestWinStreak: data?['bestWinStreak'] as int? ?? 0,
  );
}
