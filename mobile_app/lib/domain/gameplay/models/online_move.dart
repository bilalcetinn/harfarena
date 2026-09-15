import 'package:turkish_word_engine/turkish_word_engine.dart';

class OnlineMove {
  const OnlineMove({
    required this.sequence,
    required this.playerUid,
    required this.action,
    this.move,
    this.exchangeLetters = const [],
    this.createdAt,
  });

  final int sequence;
  final String playerUid;
  final String action;
  final GeneratedMove? move;
  final List<String> exchangeLetters;
  final DateTime? createdAt;

  factory OnlineMove.play({
    required int sequence,
    required String playerUid,
    required GeneratedMove move,
  }) => OnlineMove(
    sequence: sequence,
    playerUid: playerUid,
    action: 'play',
    move: move,
  );

  factory OnlineMove.pass({required int sequence, required String playerUid}) =>
      OnlineMove(sequence: sequence, playerUid: playerUid, action: 'pass');

  factory OnlineMove.exchange({
    required int sequence,
    required String playerUid,
    required List<String> letters,
  }) => OnlineMove(
    sequence: sequence,
    playerUid: playerUid,
    action: 'exchange',
    exchangeLetters: List<String>.unmodifiable(letters),
  );

  OnlineMove copyWithSequence(int value) => OnlineMove(
    sequence: value,
    playerUid: playerUid,
    action: action,
    move: move,
    exchangeLetters: exchangeLetters,
    createdAt: createdAt,
  );
}
