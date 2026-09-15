import 'package:kelime_analiz_mobile/domain/profile/models/local_settings.dart';

abstract interface class LocalSettingsRepository {
  Future<LocalSettings> load();
  Future<void> setSoundEnabled(bool value);
  Future<void> setVibrationEnabled(bool value);
  Future<void> setTurnNotificationsEnabled(bool value);
  Future<void> setInviteNotificationsEnabled(bool value);
  Future<void> setResultNotificationsEnabled(bool value);
  Future<void> setDefaultTurnDurationSeconds(int value);
}
