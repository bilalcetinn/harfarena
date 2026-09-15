abstract interface class AppNotificationRepository {
  Stream<String> get openedRoomCodes;

  Future<void> initialize();

  Future<bool> registerForPlayer(
    String playerId, {
    bool requestPermission = true,
  });

  Future<void> unregisterCurrentDevice();

  Future<void> dispose();
}
