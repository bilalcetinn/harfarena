import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/data/gameplay/services/online_game_service.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> createProfile(String uid, String username) async {
    await firestore.collection('players').doc(uid).set({'username': username});
    await firestore.collection('rooms').doc(profileDocumentCode(username)).set({
      'type': 'profile',
      'playerId': uid,
      'username': username,
      'usernameLower': username.toLowerCase(),
    });
  }

  test('friend room, memberships and invite are created together', () async {
    await createProfile('host-uid', 'Host');
    await createProfile('guest-uid', 'Guest');
    final service = OnlineGameService(
      playerId: 'host-uid',
      playerName: 'Host',
      firestore: firestore,
    );

    final room = await service.createRoom(
      targetUsername: 'Guest',
      turnDurationSeconds: 300,
    );

    final roomData = (await firestore.collection('rooms').doc(room.code).get())
        .data()!;
    expect(roomData['hostUid'], 'host-uid');
    expect(roomData['invitedGuestUid'], 'guest-uid');
    expect(roomData['lastMoveId'], isNull);

    for (final username in ['Host', 'Guest']) {
      final membership = await firestore
          .collection('rooms')
          .doc(profileDocumentCode(username))
          .collection('moves')
          .doc('membership_${room.code}')
          .get();
      expect(membership.exists, isTrue);
    }
    final invite = await firestore
        .collection('rooms')
        .doc(profileDocumentCode('Guest'))
        .collection('moves')
        .doc('invite_${room.code}')
        .get();
    expect(invite.data()?['action'], 'invite');
  });

  test('a third player cannot join a private invitation', () async {
    await createProfile('host-uid', 'Host');
    await createProfile('guest-uid', 'Guest');
    await createProfile('other-uid', 'Other');
    final host = OnlineGameService(
      playerId: 'host-uid',
      playerName: 'Host',
      firestore: firestore,
    );
    final other = OnlineGameService(
      playerId: 'other-uid',
      playerName: 'Other',
      firestore: firestore,
    );
    final room = await host.createRoom(targetUsername: 'Guest');

    await expectLater(other.joinRoom(room.code), throwsStateError);
  });

  test(
    'timeout event is written by the caller and identifies expired player',
    () async {
      final now = DateTime.utc(2026, 9, 12, 12);
      await createProfile('host-uid', 'Host');
      await createProfile('guest-uid', 'Guest');
      final host = OnlineGameService(
        playerId: 'host-uid',
        playerName: 'Host',
        firestore: firestore,
        clock: () => now,
      );
      final guest = OnlineGameService(
        playerId: 'guest-uid',
        playerName: 'Guest',
        firestore: firestore,
        clock: () => now,
      );
      final waiting = await host.createRoom(
        targetUsername: 'Guest',
        turnDurationSeconds: 120,
      );
      await guest.joinRoom(waiting.code);
      await firestore.collection('rooms').doc(waiting.code).update({
        'turnStartedAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 121)),
        ),
      });
      final expired = (await guest.room(waiting.code).first)!;

      await guest.expireTurn(expired);

      final roomData =
          (await firestore.collection('rooms').doc(waiting.code).get()).data()!;
      final moveId = roomData['lastMoveId'] as String;
      final move = await firestore
          .collection('rooms')
          .doc(waiting.code)
          .collection('moves')
          .doc(moveId)
          .get();
      expect(move.data()?['playerUid'], 'guest-uid');
      expect(move.data()?['expiredPlayerUid'], 'host-uid');
      expect(move.data()?['reason'], 'timeout');
      expect(roomData['turnUid'], 'guest-uid');
      expect(roomData['moveCount'], 1);
    },
  );
}
