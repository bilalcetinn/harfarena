import '../dictionary/word_dictionary.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/generated_move.dart';
import '../models/placement.dart';
import '../models/position.dart';
import '../rules/turkish_text.dart';
import 'score_calculator.dart';

/// Dışarıdan gelen bir hamleyi yasallık ve puan açısından doğrular.
class MoveValidator {
  const MoveValidator({
    required this.dictionary,
    this.scoreCalculator = const ScoreCalculator(),
  });

  final WordDictionary dictionary;
  final ScoreCalculator scoreCalculator;

  GeneratedMove validateAndScore({
    required Board board,
    required List<String> rack,
    required GeneratedMove move,
  }) {
    final word = tryNormalizeTurkishWord(move.word);
    if (word == null || !dictionary.contains(word)) {
      throw ArgumentError.value(move.word, 'move.word', 'Word is not valid');
    }
    if (word.length > board.size) {
      throw ArgumentError.value(move.word, 'move.word', 'Word is too long');
    }

    final normalizedRack =
        rack.map(normalizeTurkishRackLetter).toList(growable: false);
    if (normalizedRack.length > scoreCalculator.rules.rackSize) {
      throw ArgumentError.value(
        rack,
        'rack',
        'Rack cannot contain more than ${scoreCalculator.rules.rackSize} tiles',
      );
    }

    final end = move.start.translate(
      move.direction.dRow * (word.length - 1),
      move.direction.dCol * (word.length - 1),
    );
    if (!board.inBounds(move.start) || !board.inBounds(end)) {
      throw ArgumentError.value(move, 'move', 'Word is outside the board');
    }

    final before = move.start.translate(
      -move.direction.dRow,
      -move.direction.dCol,
    );
    final after = end.translate(move.direction.dRow, move.direction.dCol);
    if ((board.inBounds(before) && board.tileAt(before) != null) ||
        (board.inBounds(after) && board.tileAt(after) != null)) {
      throw ArgumentError.value(
        move,
        'move',
        'Word does not include the complete existing letter sequence',
      );
    }

    final placementByPosition = <Position, Placement>{};
    for (final placement in move.placements) {
      if (placementByPosition.containsKey(placement.position)) {
        throw ArgumentError.value(
          move.placements,
          'move.placements',
          'Duplicate placement at ${placement.position}',
        );
      }
      final letter = normalizeTurkishRackLetter(placement.letter);
      placementByPosition[placement.position] = Placement(
        position: placement.position,
        letter: letter,
        isBlank: placement.isBlank,
      );
    }

    final required = <Placement>[];
    var touchesExisting = false;
    var coversCenter = false;

    for (var i = 0; i < word.length; i++) {
      final position = move.start.translate(
        move.direction.dRow * i,
        move.direction.dCol * i,
      );
      final letter = word[i];
      final existing = board.tileAt(position);
      final placement = placementByPosition[position];

      if (position == board.center) coversCenter = true;

      if (existing != null) {
        if (placement != null || existing.letter != letter) {
          throw ArgumentError.value(
            move,
            'move',
            'Move conflicts with the tile at $position',
          );
        }
        touchesExisting = true;
        continue;
      }

      if (placement == null || placement.letter != letter) {
        throw ArgumentError.value(
          move.placements,
          'move.placements',
          'Missing or incorrect placement at $position',
        );
      }
      required.add(placement);

      final perpendicular = move.direction.perpendicular;
      final sideA = position.translate(
        -perpendicular.dRow,
        -perpendicular.dCol,
      );
      final sideB = position.translate(perpendicular.dRow, perpendicular.dCol);
      if ((board.inBounds(sideA) && board.tileAt(sideA) != null) ||
          (board.inBounds(sideB) && board.tileAt(sideB) != null)) {
        touchesExisting = true;
      }
    }

    if (required.isEmpty || required.length != placementByPosition.length) {
      throw ArgumentError.value(
        move.placements,
        'move.placements',
        'Placements must be exactly the newly occupied word cells',
      );
    }
    if (board.isEmpty && !coversCenter) {
      throw ArgumentError.value(
          move, 'move', 'The first word must cover center');
    }
    if (!board.isEmpty && !touchesExisting) {
      throw ArgumentError.value(
        move,
        'move',
        'Move must connect to an existing tile',
      );
    }

    _validateRack(required, normalizedRack);
    _validateCrossWords(board, required, move);

    final score = scoreCalculator.calculate(
      board: board,
      word: word,
      start: move.start,
      direction: move.direction,
      placements: required,
    );

    return GeneratedMove(
      word: word,
      start: move.start,
      direction: move.direction,
      placements: List<Placement>.unmodifiable(required),
      score: score.total,
      formedWords: List<FormedWord>.unmodifiable(score.formedWords),
    );
  }

  void _validateRack(List<Placement> placements, List<String> rack) {
    final counts = <String, int>{};
    for (final tile in rack) {
      counts[tile] = (counts[tile] ?? 0) + 1;
    }

    for (final placement in placements) {
      final rackTile = placement.isBlank ? '?' : placement.letter;
      final available = counts[rackTile] ?? 0;
      if (available == 0) {
        throw ArgumentError.value(
          rack,
          'rack',
          'Rack does not contain the required tile $rackTile',
        );
      }
      counts[rackTile] = available - 1;
    }
  }

  void _validateCrossWords(
    Board board,
    List<Placement> placements,
    GeneratedMove move,
  ) {
    final direction = move.direction.perpendicular;

    for (final placement in placements) {
      var start = placement.position;
      while (true) {
        final previous = start.translate(-direction.dRow, -direction.dCol);
        if (!board.inBounds(previous) || board.tileAt(previous) == null) break;
        start = previous;
      }

      final word = StringBuffer();
      var current = start;
      while (board.inBounds(current)) {
        if (current == placement.position) {
          word.write(placement.letter);
        } else {
          final tile = board.tileAt(current);
          if (tile == null) break;
          word.write(tile.letter);
        }
        current = current.translate(direction.dRow, direction.dCol);
      }

      final crossWord = word.toString();
      if (crossWord.length > 1 && !dictionary.contains(crossWord)) {
        throw ArgumentError.value(
          move,
          'move',
          'Invalid cross word: $crossWord',
        );
      }
    }
  }
}
