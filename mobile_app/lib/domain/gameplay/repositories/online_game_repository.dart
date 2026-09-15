import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

abstract interface class OnlineGameRepository {
  String get currentUid;

  Future<OnlineRoom> createRoom({
    String? targetUsername,
    int turnDurationSeconds,
  });
  Future<void> cancelInvitation(OnlineRoom room);
  Future<OnlineRoom> joinRoom(String code);
  Stream<OnlineRoom?> room(String code);
  Stream<List<OnlineRoom>> myRooms();
  Stream<List<OnlineMove>> moves(String code);
  Future<void> submitMove(OnlineRoom room, GeneratedMove move);
  Future<void> passTurn(OnlineRoom room);
  Future<void> exchangeTiles(OnlineRoom room, List<String> letters);
  Future<void> expireTurn(OnlineRoom room);
  Future<void> finishGame(
    OnlineRoom room, {
    required int hostScore,
    required int guestScore,
  });
}
