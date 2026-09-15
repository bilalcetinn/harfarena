import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

class OnlineMoveDto {
  const OnlineMoveDto._();

  static Map<String, dynamic> toMap(OnlineMove move) => {
    'sequence': move.sequence,
    'playerUid': move.playerUid,
    'action': move.action,
    if (move.move != null) 'word': move.move!.word,
    if (move.move != null) 'row': move.move!.start.row,
    if (move.move != null) 'col': move.move!.start.col,
    if (move.move != null) 'direction': move.move!.direction.name,
    if (move.move != null) 'score': move.move!.score,
    if (move.move != null)
      'placements': move.move!.placements
          .map(
            (placement) => {
              'row': placement.position.row,
              'col': placement.position.col,
              'letter': placement.letter,
              'blank': placement.isBlank,
            },
          )
          .toList(growable: false),
    if (move.exchangeLetters.isNotEmpty)
      'exchangeLetters': move.exchangeLetters,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static OnlineMove fromMap(Map<String, dynamic> data) {
    final action = data['action'] as String? ?? 'play';
    GeneratedMove? generatedMove;
    if (action == 'play') {
      generatedMove = GeneratedMove(
        word: data['word'] as String? ?? '',
        start: Position(data['row'] as int? ?? 0, data['col'] as int? ?? 0),
        direction: data['direction'] == Direction.horizontal.name
            ? Direction.horizontal
            : Direction.vertical,
        score: data['score'] as int? ?? 0,
        placements: (data['placements'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((raw) {
              final placement = raw.cast<String, dynamic>();
              return Placement(
                position: Position(
                  placement['row'] as int? ?? 0,
                  placement['col'] as int? ?? 0,
                ),
                letter: placement['letter'] as String? ?? '',
                isBlank: placement['blank'] as bool? ?? false,
              );
            })
            .toList(growable: false),
      );
    }
    return OnlineMove(
      sequence: data['sequence'] as int? ?? 0,
      playerUid: data['playerUid'] as String? ?? '',
      action: action,
      move: generatedMove,
      exchangeLetters: (data['exchangeLetters'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
