import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/data/games/services/matchmaking_service.dart';

void main() {
  test('search ticket can be watched and cancelled', () async {
    final firestore = FakeFirebaseFirestore();
    final service = MatchmakingService(firestore: firestore);
    await service.search(
      playerId: 'p1',
      username: 'Bilal',
      turnDurationSeconds: 300,
    );
    final ticket = await service.ticket('p1').first;
    expect(ticket!.isSearching, isTrue);
    expect(ticket.turnDurationSeconds, 300);
    await service.cancel('p1');
    expect(await service.ticket('p1').first, isNull);
  });
}
