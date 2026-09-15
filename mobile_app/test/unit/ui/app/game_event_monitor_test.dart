import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/online_game_repository.dart';
import 'package:kelime_analiz_mobile/ui/app/game_event_monitor.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  test('davet kabulünü ve yalnızca yeni rakip hamlesini bildirir', () async {
    final games = _FakeOnlineGames();
    final events = <AppGameEvent>[];
    final monitor = GameEventMonitor(
      games: games,
      roomsStream: games.myRooms(),
      currentPlayerId: 'host',
      onEvent: events.add,
    )..start();

    games.emitRooms(const []);
    games.emitRooms([_waitingRoom]);
    expect(events, isEmpty);

    games.emitRooms([_playingRoom]);
    expect(events, hasLength(1));
    expect(events.single, isA<GameOpenedAppGameEvent>());
    expect(events.single.opponentName, 'Ayşe');

    games.emitMoves('ROOM1234', const []);
    games.emitMoves('ROOM1234', [
      OnlineMove.play(
        sequence: 0,
        playerUid: 'guest',
        move: const GeneratedMove(
          word: 'KALEM',
          start: Position(7, 7),
          direction: Direction.horizontal,
          placements: [],
          score: 18,
        ),
      ),
    ]);

    expect(events, hasLength(2));
    final moveEvent = events.last as OpponentMoveAppGameEvent;
    expect(moveEvent.opponentName, 'Ayşe');
    expect(moveEvent.word, 'KALEM');
    expect(moveEvent.score, 18);

    await monitor.dispose();
    await games.dispose();
  });

  test('ilk snapshot içindeki geçmiş hamleyi yeniden bildirmez', () async {
    final games = _FakeOnlineGames();
    final events = <AppGameEvent>[];
    final monitor = GameEventMonitor(
      games: games,
      roomsStream: games.myRooms(),
      currentPlayerId: 'host',
      onEvent: events.add,
    )..start();

    games.emitRooms([_playingRoom]);
    games.emitMoves('ROOM1234', [
      OnlineMove.play(
        sequence: 0,
        playerUid: 'guest',
        move: const GeneratedMove(
          word: 'ESKİ',
          start: Position(7, 7),
          direction: Direction.horizontal,
          placements: [],
          score: 10,
        ),
      ),
    ]);
    expect(events, isEmpty);

    games.emitMoves('ROOM1234', [
      OnlineMove.play(
        sequence: 0,
        playerUid: 'guest',
        move: const GeneratedMove(
          word: 'ESKİ',
          start: Position(7, 7),
          direction: Direction.horizontal,
          placements: [],
          score: 10,
        ),
      ),
      OnlineMove.play(
        sequence: 1,
        playerUid: 'guest',
        move: const GeneratedMove(
          word: 'YENİ',
          start: Position(8, 7),
          direction: Direction.vertical,
          placements: [],
          score: 12,
        ),
      ),
    ]);

    expect(events, hasLength(1));
    expect((events.single as OpponentMoveAppGameEvent).word, 'YENİ');

    await monitor.dispose();
    await games.dispose();
  });
}

const _waitingRoom = OnlineRoom(
  code: 'ROOM1234',
  hostUid: 'host',
  guestUid: null,
  turnUid: 'host',
  status: 'waiting',
  seed: 42,
  turnStartedAt: null,
  hostName: 'Bilal',
  guestName: null,
  invitedGuestUid: 'guest',
  invitedGuestName: 'Ayşe',
);

const _playingRoom = OnlineRoom(
  code: 'ROOM1234',
  hostUid: 'host',
  guestUid: 'guest',
  turnUid: 'guest',
  status: 'playing',
  seed: 42,
  turnStartedAt: null,
  hostName: 'Bilal',
  guestName: 'Ayşe',
);

class _FakeOnlineGames implements OnlineGameRepository {
  final _rooms = StreamController<List<OnlineRoom>>.broadcast(sync: true);
  final _moves = <String, StreamController<List<OnlineMove>>>{};

  void emitRooms(List<OnlineRoom> rooms) => _rooms.add(rooms);

  void emitMoves(String code, List<OnlineMove> moves) {
    _moves[code]!.add(moves);
  }

  @override
  String get currentUid => 'host';

  @override
  Stream<List<OnlineRoom>> myRooms() => _rooms.stream;

  @override
  Stream<List<OnlineMove>> moves(String code) => _moves
      .putIfAbsent(
        code,
        () => StreamController<List<OnlineMove>>.broadcast(sync: true),
      )
      .stream;

  Future<void> dispose() async {
    await _rooms.close();
    await Future.wait(_moves.values.map((controller) => controller.close()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
