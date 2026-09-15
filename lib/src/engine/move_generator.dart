import '../dictionary/word_dictionary.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/generated_move.dart';
import '../models/placement.dart';
import '../models/position.dart';
import '../rules/turkish_text.dart';
import 'score_calculator.dart';

class MoveGenerator {
  MoveGenerator({
    required this.dictionary,
    this.scoreCalculator = const ScoreCalculator(),
  });

  final WordDictionary dictionary;
  final ScoreCalculator scoreCalculator;

  List<GeneratedMove> generate({
    required Board board,
    required List<String> rack,
    int? limit,
  }) {
    if (limit != null && limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be >= 0');
    }
    if (rack.length > scoreCalculator.rules.rackSize) {
      throw ArgumentError.value(
        rack,
        'rack',
        'Rack cannot contain more than ${scoreCalculator.rules.rackSize} tiles',
      );
    }

    final normalizedRack =
        rack.map(normalizeTurkishRackLetter).toList(growable: false);
    final results = <String, GeneratedMove>{};

    for (final word in dictionary.words) {
      if (word.isEmpty || word.length > board.size) continue;

      for (final direction in Direction.values) {
        final maxRow = direction == Direction.horizontal
            ? board.size - 1
            : board.size - word.length;
        final maxCol = direction == Direction.horizontal
            ? board.size - word.length
            : board.size - 1;

        for (var row = 0; row <= maxRow; row++) {
          for (var col = 0; col <= maxCol; col++) {
            final move = _tryBuildMove(
              board: board,
              rack: normalizedRack,
              word: word,
              start: Position(row, col),
              direction: direction,
            );
            if (move != null) {
              final previous = results[move.key];
              if (previous == null || move.score > previous.score) {
                results[move.key] = move;
              }
            }
          }
        }
      }
    }

    final moves = results.values.toList()
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) return scoreComparison;
        final lengthComparison = b.word.length.compareTo(a.word.length);
        if (lengthComparison != 0) return lengthComparison;
        return a.word.compareTo(b.word);
      });

    if (limit != null && moves.length > limit) {
      return moves.sublist(0, limit);
    }
    return moves;
  }

  GeneratedMove? _tryBuildMove({
    required Board board,
    required List<String> rack,
    required String word,
    required Position start,
    required Direction direction,
  }) {
    final end = start.translate(
      direction.dRow * (word.length - 1),
      direction.dCol * (word.length - 1),
    );
    if (!board.inBounds(start) || !board.inBounds(end)) return null;

    final before = start.translate(-direction.dRow, -direction.dCol);
    if (board.inBounds(before) && board.tileAt(before) != null) return null;

    final after = end.translate(direction.dRow, direction.dCol);
    if (board.inBounds(after) && board.tileAt(after) != null) return null;

    final required = <Placement>[];
    var touchesExisting = false;
    var coversCenter = false;

    for (var i = 0; i < word.length; i++) {
      final position = start.translate(direction.dRow * i, direction.dCol * i);
      final letter = word[i];
      final existing = board.tileAt(position);

      if (position == board.center) coversCenter = true;

      if (existing != null) {
        if (existing.letter != letter) return null;
        touchesExisting = true;
      } else {
        required.add(Placement(position: position, letter: letter));

        final perpendicular = direction.perpendicular;
        final sideA =
            position.translate(-perpendicular.dRow, -perpendicular.dCol);
        final sideB =
            position.translate(perpendicular.dRow, perpendicular.dCol);
        if ((board.inBounds(sideA) && board.tileAt(sideA) != null) ||
            (board.inBounds(sideB) && board.tileAt(sideB) != null)) {
          touchesExisting = true;
        }
      }
    }

    if (required.isEmpty || required.length > rack.length) return null;

    if (board.isEmpty) {
      if (!coversCenter) return null;
    } else if (!touchesExisting) {
      return null;
    }

    if (!_crossWordsAreValid(
      board: board,
      placements: required,
      mainDirection: direction,
    )) {
      return null;
    }

    final assignments = _blankAssignments(required: required, rack: rack);
    if (assignments.isEmpty) return null;

    GeneratedMove? best;
    for (final placements in assignments) {
      final score = scoreCalculator.calculate(
        board: board,
        word: word,
        start: start,
        direction: direction,
        placements: placements,
      );
      final candidate = GeneratedMove(
        word: word,
        start: start,
        direction: direction,
        placements: placements,
        score: score.total,
        formedWords: score.formedWords,
      );
      if (best == null || candidate.score > best.score) {
        best = candidate;
      }
    }
    return best;
  }

  bool _crossWordsAreValid({
    required Board board,
    required List<Placement> placements,
    required Direction mainDirection,
  }) {
    final direction = mainDirection.perpendicular;

    for (final placement in placements) {
      var start = placement.position;
      while (true) {
        final previous = start.translate(-direction.dRow, -direction.dCol);
        if (!board.inBounds(previous) || board.tileAt(previous) == null) break;
        start = previous;
      }

      final buffer = StringBuffer();
      var current = start;
      var length = 0;
      while (board.inBounds(current)) {
        if (current == placement.position) {
          buffer.write(placement.letter);
        } else {
          final tile = board.tileAt(current);
          if (tile == null) break;
          buffer.write(tile.letter);
        }
        length++;
        current = current.translate(direction.dRow, direction.dCol);
      }

      if (length > 1 && !dictionary.contains(buffer.toString())) {
        return false;
      }
    }
    return true;
  }

  List<List<Placement>> _blankAssignments({
    required List<Placement> required,
    required List<String> rack,
  }) {
    final counts = <String, int>{};
    var blanks = 0;
    for (final tile in rack) {
      if (tile == '?') {
        blanks++;
      } else {
        counts[tile] = (counts[tile] ?? 0) + 1;
      }
    }

    final results = <List<Placement>>[];

    void visit(int index, int blanksLeft, List<Placement> current) {
      if (index == required.length) {
        results.add(List<Placement>.unmodifiable(current));
        return;
      }

      final placement = required[index];
      final available = counts[placement.letter] ?? 0;

      if (available > 0) {
        counts[placement.letter] = available - 1;
        current.add(placement.copyWith(isBlank: false));
        visit(index + 1, blanksLeft, current);
        current.removeLast();
        counts[placement.letter] = available;
      }

      if (blanksLeft > 0) {
        current.add(placement.copyWith(isBlank: true));
        visit(index + 1, blanksLeft - 1, current);
        current.removeLast();
      }
    }

    visit(0, blanks, <Placement>[]);
    return results;
  }
}
