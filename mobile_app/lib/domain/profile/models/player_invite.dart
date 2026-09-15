class PlayerInvite {
  const PlayerInvite({
    required this.roomCode,
    required this.fromUsername,
    required this.sequence,
    this.turnDurationSeconds = 90,
  });

  final String roomCode;
  final String fromUsername;
  final int sequence;
  final int turnDurationSeconds;
}
