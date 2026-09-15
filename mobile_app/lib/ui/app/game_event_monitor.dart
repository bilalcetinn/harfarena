import 'dart:async';

import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/online_game_repository.dart';

sealed class AppGameEvent {
  const AppGameEvent({required this.roomCode, required this.opponentName});

  final String roomCode;
  final String opponentName;
}

final class OpponentMoveAppGameEvent extends AppGameEvent {
  const OpponentMoveAppGameEvent({
    required super.roomCode,
    required super.opponentName,
    required this.word,
    required this.score,
  });

  final String word;
  final int score;
}

final class GameOpenedAppGameEvent extends AppGameEvent {
  const GameOpenedAppGameEvent({
    required super.roomCode,
    required super.opponentName,
  });
}

/// Oturum boyunca oda ve hamle akışlarını izleyip yalnızca yeni olayları üretir.
///
/// İlk Firestore snapshot'ındaki eski maçlar ve hamleler bildirim oluşturmaz.
/// Böylece uygulama açıldığında geçmiş olaylar yeniden gösterilmez.
class GameEventMonitor {
  factory GameEventMonitor({
    required OnlineGameRepository games,
    required Stream<List<OnlineRoom>> roomsStream,
    required String currentPlayerId,
    required void Function(AppGameEvent event) onEvent,
  }) => GameEventMonitor._(games, roomsStream, currentPlayerId, onEvent);

  GameEventMonitor._(
    this._games,
    this._roomsStream,
    this._currentPlayerId,
    this._onEvent,
  );

  final OnlineGameRepository _games;
  final Stream<List<OnlineRoom>> _roomsStream;
  final String _currentPlayerId;
  final void Function(AppGameEvent event) _onEvent;

  final Map<String, OnlineRoom> _knownRooms = <String, OnlineRoom>{};
  final Map<String, StreamSubscription<List<OnlineMove>>> _moveSubscriptions =
      <String, StreamSubscription<List<OnlineMove>>>{};
  final Map<String, int> _lastMoveSequences = <String, int>{};

  StreamSubscription<List<OnlineRoom>>? _roomsSubscription;
  bool _hasRoomBaseline = false;
  bool _disposed = false;

  void start() {
    if (_roomsSubscription != null || _disposed) return;
    _roomsSubscription = _roomsStream.listen(_handleRooms);
  }

  void _handleRooms(List<OnlineRoom> rooms) {
    if (_disposed) return;

    // myRooms ilk dinlendiğinde arayüzü bekletmemek için boş bir değer üretir.
    // Bildirim tabanı olarak ilk gerçek (boş olmayan) oda listesini kullan.
    if (!_hasRoomBaseline && rooms.isEmpty) return;

    final isInitialSnapshot = !_hasRoomBaseline;
    final currentRooms = <String, OnlineRoom>{
      for (final room in rooms) room.code: room,
    };

    if (!isInitialSnapshot) {
      for (final room in rooms) {
        final previous = _knownRooms[room.code];
        final wasAccepted =
            previous != null &&
            !previous.isReady &&
            room.isReady &&
            room.hostUid == _currentPlayerId;

        if (wasAccepted) {
          _onEvent(
            GameOpenedAppGameEvent(
              roomCode: room.code,
              opponentName: _opponentName(room),
            ),
          );
        }
      }
    }

    for (final room in rooms) {
      if (!room.isReady || room.isFinished) continue;
      if (_moveSubscriptions.containsKey(room.code)) continue;

      final previous = _knownRooms[room.code];
      final becameReady = previous != null && !previous.isReady;
      _watchMoves(
        room,
        baselineSequence: becameReady ? previous.moveCount - 1 : -1,
        suppressInitialSnapshot: isInitialSnapshot || !becameReady,
      );
    }

    final activeCodes = <String>{
      for (final room in rooms)
        if (room.isReady && !room.isFinished) room.code,
    };
    for (final code in _moveSubscriptions.keys.toList(growable: false)) {
      if (activeCodes.contains(code)) continue;
      unawaited(_moveSubscriptions.remove(code)?.cancel());
      _lastMoveSequences.remove(code);
    }

    _knownRooms
      ..clear()
      ..addAll(currentRooms);
    _hasRoomBaseline = true;
  }

  void _watchMoves(
    OnlineRoom room, {
    required int baselineSequence,
    required bool suppressInitialSnapshot,
  }) {
    var isFirstSnapshot = true;
    _lastMoveSequences[room.code] = baselineSequence;
    _moveSubscriptions[room.code] = _games.moves(room.code).listen((moves) {
      if (_disposed) return;

      final ordered = moves.toList(growable: false)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      final newestSequence = ordered.isEmpty
          ? baselineSequence
          : ordered.last.sequence;

      if (isFirstSnapshot && suppressInitialSnapshot) {
        isFirstSnapshot = false;
        _lastMoveSequences[room.code] = newestSequence;
        return;
      }
      isFirstSnapshot = false;

      final previousSequence = _lastMoveSequences[room.code] ?? -1;
      for (final event in ordered) {
        final move = event.move;
        if (event.sequence <= previousSequence ||
            event.playerUid == _currentPlayerId ||
            event.action != 'play' ||
            move == null) {
          continue;
        }
        _onEvent(
          OpponentMoveAppGameEvent(
            roomCode: room.code,
            opponentName: _opponentName(room),
            word: move.word,
            score: move.score,
          ),
        );
      }
      _lastMoveSequences[room.code] = newestSequence;
    });
  }

  String _opponentName(OnlineRoom room) {
    if (room.hostUid == _currentPlayerId) {
      return room.guestName ?? room.invitedGuestName ?? 'Rakip';
    }
    return room.hostName;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final subscriptions = _moveSubscriptions.values.toList(growable: false);
    _moveSubscriptions.clear();
    _lastMoveSequences.clear();
    _knownRooms.clear();
    await Future.wait<void>([
      if (_roomsSubscription != null) _roomsSubscription!.cancel(),
      for (final subscription in subscriptions) subscription.cancel(),
    ]);
  }
}
