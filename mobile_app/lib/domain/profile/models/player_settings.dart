class PlayerSettings {
  const PlayerSettings({
    this.soundEffects = true,
    this.vibration = true,
    this.turnNotifications = true,
    this.inviteNotifications = true,
    this.resultNotifications = true,
    this.defaultTurnDurationSeconds = 120,
    this.theme = 'system',
  });

  final bool soundEffects;
  final bool vibration;
  final bool turnNotifications;
  final bool inviteNotifications;
  final bool resultNotifications;
  final int defaultTurnDurationSeconds;
  final String theme;
}
