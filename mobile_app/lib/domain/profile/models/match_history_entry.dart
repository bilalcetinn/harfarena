class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.roomCode,
    required this.hostName,
    required this.guestName,
    required this.hostScore,
    required this.guestScore,
    required this.sequence,
    this.winnerUid,
  });

  final String roomCode;
  final String hostName;
  final String guestName;
  final int hostScore;
  final int guestScore;
  final int sequence;
  final String? winnerUid;

  MatchOutcome outcomeFor({
    required String playerId,
    required String username,
  }) {
    final recordedWinner = winnerUid;
    if (recordedWinner != null && recordedWinner.isNotEmpty) {
      return recordedWinner == playerId ? MatchOutcome.win : MatchOutcome.loss;
    }

    final isHost = hostName.toLowerCase() == username.toLowerCase();
    final myScore = isHost ? hostScore : guestScore;
    final opponentScore = isHost ? guestScore : hostScore;
    if (myScore > opponentScore) return MatchOutcome.win;
    if (myScore < opponentScore) return MatchOutcome.loss;
    return MatchOutcome.draw;
  }
}

enum MatchOutcome { win, loss, draw }
