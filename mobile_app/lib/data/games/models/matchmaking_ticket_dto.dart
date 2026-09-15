import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelime_analiz_mobile/domain/games/models/matchmaking_ticket.dart';

class MatchmakingTicketDto {
  const MatchmakingTicketDto._();

  static MatchmakingTicket fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return MatchmakingTicket(
      playerId: snapshot.id,
      status: data['status'] as String? ?? 'searching',
      turnDurationSeconds: data['turnDurationSeconds'] as int? ?? 86400,
      roomCode: data['roomCode'] as String?,
      opponentName: data['opponentName'] as String?,
    );
  }
}
