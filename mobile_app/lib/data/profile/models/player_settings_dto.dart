import 'package:kelime_analiz_mobile/domain/profile/models/player_settings.dart';

class PlayerSettingsDto {
  const PlayerSettingsDto._();

  static Map<String, dynamic> toMap(PlayerSettings settings) => {
    'soundEffects': settings.soundEffects,
    'vibration': settings.vibration,
    'turnNotifications': settings.turnNotifications,
    'inviteNotifications': settings.inviteNotifications,
    'resultNotifications': settings.resultNotifications,
    'defaultTurnDurationSeconds': settings.defaultTurnDurationSeconds,
    'theme': settings.theme,
  };

  static PlayerSettings fromMap(Map<String, dynamic>? data) => PlayerSettings(
    soundEffects: data?['soundEffects'] as bool? ?? true,
    vibration: data?['vibration'] as bool? ?? true,
    turnNotifications: data?['turnNotifications'] as bool? ?? true,
    inviteNotifications: data?['inviteNotifications'] as bool? ?? true,
    resultNotifications: data?['resultNotifications'] as bool? ?? true,
    defaultTurnDurationSeconds:
        data?['defaultTurnDurationSeconds'] as int? ?? 120,
    theme: data?['theme'] as String? ?? 'system',
  );
}
