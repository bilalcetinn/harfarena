import 'package:kelime_analiz_mobile/domain/profile/models/player_progression.dart';

class PlayerStats {
  const PlayerStats({
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalScore = 0,
    this.totalPlaySeconds = 0,
    this.weeklyScore = 0,
    this.xp = 0,
    this.analysisAccuracyTotal = 0,
    this.analyzedGames = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
  });

  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final int totalScore;
  final int totalPlaySeconds;
  final int weeklyScore;
  final int xp;
  final double analysisAccuracyTotal;
  final int analyzedGames;
  final int winStreak;
  final int bestWinStreak;

  double get winRate => totalGames == 0 ? 0 : wins * 100 / totalGames;
  double get analysisAccuracy =>
      analyzedGames == 0 ? 0 : analysisAccuracyTotal / analyzedGames;
  PlayerProgression get progression => PlayerProgression.fromXp(xp);
  int get level => progression.level;
}
