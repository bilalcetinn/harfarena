class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.username,
    required this.score,
    required this.wins,
    required this.level,
  });

  final String playerId;
  final String username;
  final int score;
  final int wins;
  final int level;
}
