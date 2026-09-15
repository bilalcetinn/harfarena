import 'package:kelime_analiz_mobile/domain/games/repositories/game_invite_actions_repository.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:kelime_analiz_mobile/data/gameplay/models/online_room_dto.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameInviteActionsService implements GameInviteActionsRepository {
  GameInviteActionsService({
    required this._playerId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String _playerId;
  final FirebaseFirestore _firestore;

  @override
  Future<void> cancelOrRejectInvite(OnlineRoom room) async {
    final roomRef = _firestore.collection('rooms').doc(room.code);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final data = snapshot.data();

      if (!snapshot.exists || !OnlineRoomDto.isRoomData(data)) {
        throw StateError('Bu davet artık mevcut değil.');
      }

      if (data!['status'] != 'waiting' || data['guestUid'] != null) {
        throw StateError('Bu davetin durumu değişmiş.');
      }

      final hostUid = data['hostUid'] as String;
      final invitedGuestUid = data['invitedGuestUid'] as String?;
      final invitedGuestName = data['invitedGuestName'] as String?;

      final canChange = hostUid == _playerId || invitedGuestUid == _playerId;
      if (!canChange) {
        throw StateError('Bu davet üzerinde işlem yapamazsın.');
      }

      transaction.update(roomRef, {
        'status': 'cancelled',
        'invitedGuestUid': null,
        'invitedGuestName': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (invitedGuestName != null && invitedGuestName.isNotEmpty) {
        final profileRef = _firestore
            .collection('rooms')
            .doc(profileDocumentCode(invitedGuestName));
        final inviteRef = profileRef
            .collection('moves')
            .doc('invite_${room.code}');

        // Event'i silmek yerine aksiyonunu değiştiriyoruz. Böylece
        // roomCodes/invitations sorguları iptal edilmiş daveti artık aktif
        // davet olarak görmüyor.
        transaction.set(inviteRef, {
          'action': 'invite_cancelled',
          'roomCode': room.code,
          'cancelledAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }
}
