import 'package:kelime_analiz_mobile/domain/profile/models/player_settings.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_stats.dart';

class PlayerBackendProfile {
  const PlayerBackendProfile({
    required this.playerId,
    required this.username,
    this.displayName = '',
    this.tagline = '',
    this.avatarUrl,
    this.settings = const PlayerSettings(),
    this.stats = const PlayerStats(),
  });

  final String playerId;
  final String username;
  final String displayName;
  final String tagline;
  final String? avatarUrl;
  final PlayerSettings settings;
  final PlayerStats stats;

  String get visibleName =>
      displayName.trim().isEmpty ? username : displayName.trim();
}
