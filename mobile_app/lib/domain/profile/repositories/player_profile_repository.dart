import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_invite.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';

abstract interface class PlayerProfileRepository {
  Future<PlayerProfile?> load();
  Future<void> logout();
  Future<PlayerProfile?> findByUsername(String username);
  Future<PlayerProfile> register(String username);
  Future<void> sendInvite({
    required String targetUsername,
    required String roomCode,
    required String fromUsername,
  });
  Stream<List<PlayerInvite>> invitations(String username);
  Stream<Set<String>> roomCodes(String username);
  Stream<List<MatchHistoryEntry>> history(String username);
}
