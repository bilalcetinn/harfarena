import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';

class OnlineRoomDto {
  const OnlineRoomDto._();

  static bool isRoomData(Map<String, dynamic>? data) =>
      data != null &&
      data['type'] != 'profile' &&
      data['hostUid'] is String &&
      data['turnUid'] is String &&
      data['seed'] is int;

  static OnlineRoom fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) => fromMap(snapshot.id, snapshot.data()!);

  static OnlineRoom fromMap(String code, Map<String, dynamic> data) =>
      OnlineRoom(
        code: code,
        hostUid: data['hostUid'] as String? ?? '',
        guestUid: data['guestUid'] as String?,
        turnUid: data['turnUid'] as String? ?? '',
        status: data['status'] as String? ?? 'waiting',
        seed: data['seed'] as int? ?? 0,
        turnStartedAt: (data['turnStartedAt'] as Timestamp?)?.toDate(),
        hostName: data['hostName'] as String? ?? 'Oyuncu 1',
        guestName: data['guestName'] as String?,
        turnDurationSeconds: data['turnDurationSeconds'] as int? ?? 90,
        moveCount: data['moveCount'] as int? ?? 0,
        updatedAt: ((data['updatedAt'] ?? data['createdAt']) as Timestamp?)
            ?.toDate(),
        startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
        finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
        invitedGuestUid: data['invitedGuestUid'] as String?,
        invitedGuestName: data['invitedGuestName'] as String?,
        endedBy: data['endedBy'] as String?,
        winnerUid: data['winnerUid'] as String?,
        hostScore: data['hostScore'] as int? ?? 0,
        guestScore: data['guestScore'] as int? ?? 0,
      );
}
