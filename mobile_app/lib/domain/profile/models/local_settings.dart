class LocalSettings {
  const LocalSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.turnNotificationsEnabled = true,
    this.inviteNotificationsEnabled = true,
    this.resultNotificationsEnabled = true,
    this.defaultTurnDurationSeconds = 120,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool turnNotificationsEnabled;
  final bool inviteNotificationsEnabled;
  final bool resultNotificationsEnabled;
  final int defaultTurnDurationSeconds;
}
