import 'package:kelime_analiz_mobile/domain/profile/models/player_settings.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/data/profile/services/player_backend_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PlayerBackendService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = PlayerBackendService(firestore: firestore);
  });

  test(
    'profile defaults support Stitch profile and settings screens',
    () async {
      const player = PlayerProfile(id: 'p1', username: 'Bilal');
      await service.ensureProfile(player);
      await Future<void>.delayed(Duration.zero);
      final profile = await service.profile('p1').first;
      expect(profile!.username, 'Bilal');
      expect(profile.displayName, 'Bilal');
      expect(profile.stats.level, 1);
      expect(profile.stats.winRate, 0);
      expect(profile.settings.turnNotifications, isTrue);

      await service.updateSettings(
        'p1',
        const PlayerSettings(soundEffects: false, theme: 'dark'),
      );
      final changed = await service.profile('p1').first;
      expect(changed!.settings.soundEffects, isFalse);
      expect(changed.settings.theme, 'dark');

      await service.updatePublicProfile(
        playerId: 'p1',
        displayName: 'Bilal Cetin',
      );
      final renamed = await service.profile('p1').first;
      expect(renamed!.visibleName, 'Bilal Cetin');
      expect(renamed.username, 'Bilal');
    },
  );

  test('analysis performance is recorded once for each match', () async {
    const player = PlayerProfile(id: 'p1', username: 'Bilal');
    await service.ensureProfile(player);
    await Future<void>.delayed(Duration.zero);
    await service.recordAnalysis(
      playerId: 'p1',
      roomCode: 'ABCDEFGH',
      accuracy: 82.5,
    );
    await Future<void>.delayed(Duration.zero);
    await service.recordAnalysis(
      playerId: 'p1',
      roomCode: 'ABCDEFGH',
      accuracy: 20,
    );
    await Future<void>.delayed(Duration.zero);
    final profile = await service.profile('p1').first;
    expect(profile!.stats.analyzedGames, 1);
    expect(profile.stats.analysisAccuracy, 82.5);
  });

  test('leaderboards are ordered by score', () async {
    await firestore.collection('leaderboard_weekly').doc('a').set({
      'username': 'Ada',
      'score': 20,
      'wins': 1,
      'level': 2,
    });
    await firestore.collection('leaderboard_weekly').doc('b').set({
      'username': 'Can',
      'score': 80,
      'wins': 3,
      'level': 4,
    });
    final entries = await service.leaderboard(weekly: true).first;
    expect(entries.map((entry) => entry.username), ['Can', 'Ada']);
  });
}
