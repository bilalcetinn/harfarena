import 'dart:typed_data';

import 'package:kelime_analiz_mobile/domain/profile/models/player_backend_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_settings.dart';

abstract interface class PlayerProfileDetailsRepository {
  Stream<PlayerBackendProfile?> profile(String playerId);

  Future<void> ensureProfile(PlayerProfile profile);

  Future<void> updatePublicProfile({
    required String playerId,
    required String displayName,
    String? avatarUrl,
  });

  Future<String> uploadAvatar({
    required String playerId,
    required Uint8List bytes,
    String contentType,
  });

  Future<void> updateSettings(String playerId, PlayerSettings settings);
}
