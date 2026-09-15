import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/data/gameplay/services/online_game_service.dart';
import 'package:kelime_analiz_mobile/domain/analysis/models/word_definition.dart';
import 'package:kelime_analiz_mobile/domain/analysis/repositories/word_definition_repository.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/game_audio_repository.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/online_lobby_view.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  testWidgets('drag preview validates and only valid words can play', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = FakeFirebaseFirestore();
    final host = OnlineGameService(
      playerId: 'host',
      playerName: 'Bilal',
      firestore: db,
    );
    const room = OnlineRoom(
      code: 'TEST2222',
      hostUid: 'host',
      guestUid: 'guest',
      turnUid: 'host',
      status: 'playing',
      seed: 42,
      turnStartedAt: null,
      hostName: 'Bilal',
      guestName: 'Rakip',
      turnDurationSeconds: 0,
    );
    await db.collection('rooms').doc(room.code).set({
      'type': 'match',
      'hostUid': room.hostUid,
      'guestUid': room.guestUid,
      'turnUid': room.turnUid,
      'status': room.status,
      'seed': room.seed,
      'turnStartedAt': Timestamp.now(),
      'hostName': room.hostName,
      'guestName': room.guestName,
      'turnDurationSeconds': 0,
      'moveCount': 0,
    });
    final rack = TileBag(random: Random(room.seed)).draw(7);
    final indices = [
      for (var i = 0; i < rack.length; i++)
        if (rack[i] != '?') i,
    ];
    final first = indices[0];
    final second = indices[1];
    final word = '${rack[first]}${rack[second]}';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnlineMatchView(
            room: room,
            service: host,
            dictionary: TrieWordDictionary([word]),
            audio: _RecordingAudioRepository(),
            definitions: const _EmptyDefinitionRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('∞'), findsOneWidget);

    Future<void> drag(int index, int col) async {
      final rackFinder = find.byKey(ValueKey('rack-$index'));
      final cellFinder = find.byKey(ValueKey('cell-7-$col'));
      await tester.dragFrom(
        tester.getCenter(rackFinder),
        tester.getCenter(cellFinder) - tester.getCenter(rackFinder),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    FilledButton playButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'OYNA'));
    await drag(first, 7);
    expect(playButton().onPressed, isNull);
    await drag(second, 8);
    expect(playButton().onPressed, isNotNull);
    await tester.drag(
      find.byKey(const ValueKey('cell-7-8')),
      tester.getCenter(find.byKey(const ValueKey('cell-7-9'))) -
          tester.getCenter(find.byKey(const ValueKey('cell-7-8'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(playButton().onPressed, isNull);
    await tester.drag(
      find.byKey(const ValueKey('cell-7-9')),
      tester.getCenter(find.byKey(const ValueKey('rack-drop-zone'))) -
          tester.getCenter(find.byKey(const ValueKey('cell-7-9'))),
    );
    await tester.pump();
    expect(find.byKey(ValueKey('rack-$second')), findsOneWidget);
    await tester.pump(const Duration(seconds: 95));
    final storedMoves = await db
        .collection('rooms')
        .doc(room.code)
        .collection('moves')
        .get();
    expect(storedMoves.docs, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'rakip sırasında deneme ve çift dokunarak yakınlaştırma çalışır',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      const room = OnlineRoom(
        code: 'RIVAL222',
        hostUid: 'host',
        guestUid: 'guest',
        turnUid: 'guest',
        status: 'playing',
        seed: 43,
        turnStartedAt: null,
        hostName: 'Bilal',
        guestName: 'Rakip',
        turnDurationSeconds: 0,
      );
      await db.collection('rooms').doc(room.code).set({
        'type': 'match',
        'hostUid': room.hostUid,
        'guestUid': room.guestUid,
        'turnUid': room.turnUid,
        'status': room.status,
        'seed': room.seed,
        'turnStartedAt': Timestamp.now(),
        'hostName': room.hostName,
        'guestName': room.guestName,
        'turnDurationSeconds': 0,
        'moveCount': 0,
      });
      final service = OnlineGameService(
        playerId: 'host',
        playerName: 'Bilal',
        firestore: db,
      );
      final rack = TileBag(random: Random(room.seed)).draw(7);
      final first = rack.indexWhere((letter) => letter != '?');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnlineMatchView(
              room: room,
              service: service,
              dictionary: TrieWordDictionary(const ['AT']),
              audio: _RecordingAudioRepository(),
              definitions: const _EmptyDefinitionRepository(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Rakibin Sırası'), findsOneWidget);
      await tester.dragFrom(
        tester.getCenter(find.byKey(ValueKey('rack-$first'))),
        tester.getCenter(find.byKey(const ValueKey('cell-7-7'))) -
            tester.getCenter(find.byKey(ValueKey('rack-$first'))),
      );
      await tester.pump();
      expect(find.byKey(ValueKey('rack-$first')), findsNothing);
      final play = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'OYNA'),
      );
      expect(play.onPressed, isNull);
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(const Duration(milliseconds: 100));
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 2.2);
      expect(find.textContaining('taş'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('should play turn sound when the turn becomes mine', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final service = OnlineGameService(
      playerId: 'host',
      playerName: 'Bilal',
      firestore: db,
    );
    final audio = _RecordingAudioRepository();

    const rivalTurn = OnlineRoom(
      code: 'SOUND002',
      hostUid: 'host',
      guestUid: 'guest',
      turnUid: 'guest',
      status: 'playing',
      seed: 13,
      turnStartedAt: null,
      hostName: 'Bilal',
      guestName: 'Rakip',
    );
    const myTurn = OnlineRoom(
      code: 'SOUND002',
      hostUid: 'host',
      guestUid: 'guest',
      turnUid: 'host',
      status: 'playing',
      seed: 13,
      turnStartedAt: null,
      hostName: 'Bilal',
      guestName: 'Rakip',
    );

    await db.collection('rooms').doc(rivalTurn.code).set({
      'type': 'match',
      'hostUid': rivalTurn.hostUid,
      'guestUid': rivalTurn.guestUid,
      'turnUid': rivalTurn.turnUid,
      'status': rivalTurn.status,
      'seed': rivalTurn.seed,
      'hostName': rivalTurn.hostName,
      'guestName': rivalTurn.guestName,
      'turnDurationSeconds': rivalTurn.turnDurationSeconds,
      'moveCount': 0,
    });

    Widget match(OnlineRoom room) => MaterialApp(
      home: Scaffold(
        body: OnlineMatchView(
          room: room,
          service: service,
          dictionary: TrieWordDictionary(const ['AT']),
          audio: audio,
          definitions: const _EmptyDefinitionRepository(),
        ),
      ),
    );

    await tester.pumpWidget(match(rivalTurn));
    await tester.pump();
    expect(audio.sounds, isEmpty);

    await tester.pumpWidget(match(myTurn));
    await tester.pump();
    expect(audio.sounds, [GameSound.turn]);
    expect(audio.sounds, isNot(contains(GameSound.tileDrop)));
  });

  testWidgets(
    'should play result sound only when an active match becomes finished',
    (tester) async {
      final db = FakeFirebaseFirestore();
      final service = OnlineGameService(
        playerId: 'host',
        playerName: 'Bilal',
        firestore: db,
      );
      final audio = _RecordingAudioRepository();

      const playingRoom = OnlineRoom(
        code: 'SOUND001',
        hostUid: 'host',
        guestUid: 'guest',
        turnUid: 'host',
        status: 'playing',
        seed: 12,
        turnStartedAt: null,
        hostName: 'Bilal',
        guestName: 'Rakip',
      );
      const finishedRoom = OnlineRoom(
        code: 'SOUND001',
        hostUid: 'host',
        guestUid: 'guest',
        turnUid: 'host',
        status: 'finished',
        seed: 12,
        turnStartedAt: null,
        hostName: 'Bilal',
        guestName: 'Rakip',
        endedBy: 'guest',
      );

      await db.collection('rooms').doc(playingRoom.code).set({
        'type': 'match',
        'hostUid': playingRoom.hostUid,
        'guestUid': playingRoom.guestUid,
        'turnUid': playingRoom.turnUid,
        'status': playingRoom.status,
        'seed': playingRoom.seed,
        'hostName': playingRoom.hostName,
        'guestName': playingRoom.guestName,
        'turnDurationSeconds': playingRoom.turnDurationSeconds,
        'moveCount': 0,
      });

      Widget match(OnlineRoom room) => MaterialApp(
        home: Scaffold(
          body: OnlineMatchView(
            room: room,
            service: service,
            dictionary: TrieWordDictionary(const ['AT']),
            audio: audio,
            definitions: const _EmptyDefinitionRepository(),
          ),
        ),
      );

      // A previously completed match opens silently.
      await tester.pumpWidget(match(finishedRoom));
      await tester.pump();
      expect(audio.sounds, isEmpty);

      // A live match emits the result sound only on its finished transition.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(match(playingRoom));
      await tester.pump();
      await tester.pumpWidget(match(finishedRoom));
      await tester.pump();
      expect(audio.sounds, [GameSound.win]);

      await tester.pumpWidget(match(finishedRoom));
      await tester.pump();
      expect(audio.sounds, [GameSound.win]);
    },
  );
}

class _RecordingAudioRepository implements GameAudioRepository {
  final sounds = <GameSound>[];

  @override
  Future<void> play(GameSound sound) async => sounds.add(sound);

  @override
  Future<void> setEnabled(bool value) async {}

  @override
  Future<void> dispose() async {}
}

class _EmptyDefinitionRepository implements WordDefinitionRepository {
  const _EmptyDefinitionRepository();

  @override
  Future<WordDefinition> lookup(String word) async =>
      WordDefinition(word: word, meanings: const []);
}
