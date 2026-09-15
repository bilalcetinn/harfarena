import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/leaderboard_entry.dart';

class LeaderboardEntryDto {
  const LeaderboardEntryDto._();

  static LeaderboardEntry fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return LeaderboardEntry(
      playerId: document.id,
      username: data['username'] as String? ?? 'Oyuncu',
      score: data['score'] as int? ?? 0,
      wins: data['wins'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
    );
  }
}
