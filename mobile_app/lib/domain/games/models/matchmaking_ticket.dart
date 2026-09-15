class MatchmakingTicket {
  const MatchmakingTicket({
    required this.playerId,
    required this.status,
    required this.turnDurationSeconds,
    this.roomCode,
    this.opponentName,
  });

  final String playerId;
  final String status;
  final int turnDurationSeconds;
  final String? roomCode;
  final String? opponentName;

  bool get isSearching => status == 'searching';
  bool get isMatched => status == 'matched' && roomCode != null;
}
