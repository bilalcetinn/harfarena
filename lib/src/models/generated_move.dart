import 'direction.dart';
import 'placement.dart';
import 'position.dart';

class FormedWord {
  const FormedWord({
    required this.word,
    required this.start,
    required this.direction,
    required this.score,
  });

  final String word;
  final Position start;
  final Direction direction;
  final int score;
}

class GeneratedMove {
  const GeneratedMove({
    required this.word,
    required this.start,
    required this.direction,
    required this.placements,
    required this.score,
    this.formedWords = const [],
  });

  final String word;
  final Position start;
  final Direction direction;
  final List<Placement> placements;
  final int score;
  final List<FormedWord> formedWords;

  String get key => '${start.row}:${start.col}:${direction.name}:$word:'
      '${placements.map((p) => '${p.position.row},${p.position.col},${p.isBlank ? 1 : 0}').join('|')}';

  @override
  String toString() => '$word @ $start ${direction.name} = $score';
}
