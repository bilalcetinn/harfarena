const kDefaultTurnDurationSeconds = 86400;
const kTurnDurationOptions = <int>[120, 300, 900, 3600, 86400, 0];

String formatTurnDuration(int seconds) {
  if (seconds == 0) return 'Süresiz';
  if (seconds % 3600 == 0) return '${seconds ~/ 3600} saat';
  if (seconds % 60 == 0) return '${seconds ~/ 60} dakika';
  return '$seconds saniye';
}

int? remainingTurnSeconds({
  required int durationSeconds,
  required DateTime? startedAt,
  required DateTime now,
}) {
  if (durationSeconds == 0) return null;
  if (startedAt == null) return durationSeconds;
  final remainingMillis = startedAt
      .add(Duration(seconds: durationSeconds))
      .difference(now)
      .inMilliseconds;
  return (remainingMillis / 1000).ceil().clamp(0, durationSeconds);
}
