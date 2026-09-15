import 'package:kelime_analiz_mobile/data/profile/models/player_settings_dto.dart';
import 'package:kelime_analiz_mobile/data/profile/models/player_stats_dto.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_backend_profile.dart';

class PlayerBackendProfileDto {
  const PlayerBackendProfileDto._();

  static PlayerBackendProfile fromMap(
    String playerId,
    Map<String, dynamic> data,
  ) => PlayerBackendProfile(
    playerId: playerId,
    username: data['username'] as String? ?? 'Oyuncu',
    displayName:
        data['displayName'] as String? ??
        data['username'] as String? ??
        'Oyuncu',
    tagline: data['tagline'] as String? ?? '',
    avatarUrl: data['avatarUrl'] as String?,
    settings: PlayerSettingsDto.fromMap(
      (data['settings'] as Map?)?.cast<String, dynamic>(),
    ),
    stats: PlayerStatsDto.fromMap(
      (data['stats'] as Map?)?.cast<String, dynamic>(),
    ),
  );
}
