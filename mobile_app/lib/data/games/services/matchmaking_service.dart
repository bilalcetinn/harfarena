import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kelime_analiz_mobile/domain/games/models/matchmaking_ticket.dart';
import 'package:kelime_analiz_mobile/data/games/models/matchmaking_ticket_dto.dart';

/// Client side of random matchmaking. A Firebase function atomically pairs
/// compatible searching tickets and writes the resulting room code back.
class MatchmakingService {
  MatchmakingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String playerId) =>
      _firestore.collection('matchmaking_queue').doc(playerId);

  Future<void> search({
    required String playerId,
    required String username,
    required int turnDurationSeconds,
  }) => _ref(playerId).set({
    'playerId': playerId,
    'username': username,
    'turnDurationSeconds': turnDurationSeconds,
    'status': 'searching',
    'roomCode': null,
    'opponentName': null,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Stream<MatchmakingTicket?> ticket(String playerId) => _ref(playerId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? MatchmakingTicketDto.fromSnapshot(snapshot)
            : null,
      );

  Future<void> cancel(String playerId) => _ref(playerId).delete();
}
