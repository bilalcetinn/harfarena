import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';

class OnlineRoom {
  const OnlineRoom({
    required this.code,
    required this.hostUid,
    required this.guestUid,
    required this.turnUid,
    required this.status,
    required this.seed,
    required this.turnStartedAt,
    required this.hostName,
    required this.guestName,
    this.turnDurationSeconds = 90,
    this.moveCount = 0,
    this.updatedAt,
    this.startedAt,
    this.finishedAt,
    this.invitedGuestUid,
    this.invitedGuestName,
    this.endedBy,
    this.winnerUid,
    this.hostScore = 0,
    this.guestScore = 0,
  });

  final String code;
  final String hostUid;
  final String? guestUid;
  final String turnUid;
  final String status;
  final int seed;
  final DateTime? turnStartedAt;
  final String hostName;
  final String? guestName;
  final int turnDurationSeconds;
  final int moveCount;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? invitedGuestUid;
  final String? invitedGuestName;
  final String? endedBy;
  final String? winnerUid;
  final int hostScore;
  final int guestScore;

  bool get isReady => guestUid != null && status == 'playing';
  bool get isFinished => status == 'finished';
  bool get isCancelled => status == 'cancelled';

  int? remainingSeconds({DateTime? now}) => remainingTurnSeconds(
    durationSeconds: turnDurationSeconds,
    startedAt: turnStartedAt,
    now: now ?? DateTime.now(),
  );

  bool isExpired({DateTime? now}) =>
      isReady && turnStartedAt != null && remainingSeconds(now: now) == 0;
}
