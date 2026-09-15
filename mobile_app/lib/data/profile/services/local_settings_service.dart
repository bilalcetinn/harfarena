import 'package:kelime_analiz_mobile/domain/profile/repositories/local_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kelime_analiz_mobile/domain/profile/models/local_settings.dart';

class LocalSettingsService implements LocalSettingsRepository {
  static const _soundKey = 'settings_sound_enabled';
  static const _vibrationKey = 'settings_vibration_enabled';
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _turnNotificationsKey = 'settings_turn_notifications_enabled';
  static const _inviteNotificationsKey =
      'settings_invite_notifications_enabled';
  static const _resultNotificationsKey =
      'settings_result_notifications_enabled';
  static const _defaultTurnDurationKey =
      'settings_default_turn_duration_seconds';

  @override
  Future<LocalSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final legacyNotifications = preferences.getBool(_notificationsKey) ?? true;
    return LocalSettings(
      soundEnabled: preferences.getBool(_soundKey) ?? true,
      vibrationEnabled: preferences.getBool(_vibrationKey) ?? true,
      turnNotificationsEnabled:
          preferences.getBool(_turnNotificationsKey) ?? legacyNotifications,
      inviteNotificationsEnabled:
          preferences.getBool(_inviteNotificationsKey) ?? legacyNotifications,
      resultNotificationsEnabled:
          preferences.getBool(_resultNotificationsKey) ?? legacyNotifications,
      defaultTurnDurationSeconds:
          preferences.getInt(_defaultTurnDurationKey) ?? 120,
    );
  }

  @override
  Future<void> setSoundEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_soundKey, value);
  }

  @override
  Future<void> setVibrationEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_vibrationKey, value);
  }

  @override
  Future<void> setTurnNotificationsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_turnNotificationsKey, value);
  }

  @override
  Future<void> setInviteNotificationsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_inviteNotificationsKey, value);
  }

  @override
  Future<void> setResultNotificationsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_resultNotificationsKey, value);
  }

  @override
  Future<void> setDefaultTurnDurationSeconds(int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_defaultTurnDurationKey, value);
  }
}
