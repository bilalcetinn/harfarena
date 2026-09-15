import '../models/board.dart';
import '../models/direction.dart';
import '../models/generated_move.dart';
import '../models/placement.dart';
import '../models/position.dart';
import '../models/premium_type.dart';
import '../rules/kelime_rules.dart';

class ScoreResult {
  const ScoreResult({required this.total, required this.formedWords});

  final int total;
  final List<FormedWord> formedWords;
}

class ScoreCalculator {
  const ScoreCalculator({this.rules = const KelimeRules()});

  final KelimeRules rules;

  ScoreResult calculate({
    required Board board,
    required String word,
    required Position start,
    required Direction direction,
    required List<Placement> placements,
  }) {
    final placementByPosition = {
      for (final placement in placements) placement.position: placement,
    };

    final main = _scoreKnownWord(
      board: board,
      word: word,
      start: start,
      direction: direction,
      placementByPosition: placementByPosition,
    );

    var total = main.score;
    final formedWords = <FormedWord>[main];

    for (final placement in placements) {
      final cross = _buildAndScoreCrossWord(
        board: board,
        placement: placement,
        mainDirection: direction,
        placementByPosition: placementByPosition,
      );
      if (cross != null) {
        total += cross.score;
        formedWords.add(cross);
      }
    }

    if (placements.length == rules.rackSize) {
      total += rules.fullRackBonus;
    }

    return ScoreResult(total: total, formedWords: formedWords);
  }

  FormedWord _scoreKnownWord({
    required Board board,
    required String word,
    required Position start,
    required Direction direction,
    required Map<Position, Placement> placementByPosition,
  }) {
    var letterTotal = 0;
    var wordMultiplier = 1;
    var additiveBonus = 0;

    for (var i = 0; i < word.length; i++) {
      final position = start.translate(direction.dRow * i, direction.dCol * i);
      final placement = placementByPosition[position];

      if (placement != null) {
        final cell = board.cellAt(position);
        var points = placement.isBlank ? 0 : rules.pointsFor(placement.letter);

        switch (cell.premium) {
          case PremiumType.doubleLetter:
            points *= 2;
            break;
          case PremiumType.tripleLetter:
            points *= 3;
            break;
          case PremiumType.doubleWord:
            wordMultiplier *= 2;
            break;
          case PremiumType.tripleWord:
            wordMultiplier *= 3;
            break;
          case PremiumType.bonus25:
            additiveBonus += rules.randomBonusPoints;
            break;
          case PremiumType.none:
            break;
        }
        letterTotal += points;
      } else {
        final tile = board.tileAt(position);
        if (tile == null) {
          throw StateError('Expected an existing tile at $position.');
        }
        letterTotal += tile.isBlank ? 0 : rules.pointsFor(tile.letter);
      }
    }

    return FormedWord(
      word: word,
      start: start,
      direction: direction,
      score: letterTotal * wordMultiplier + additiveBonus,
    );
  }

  FormedWord? _buildAndScoreCrossWord({
    required Board board,
    required Placement placement,
    required Direction mainDirection,
    required Map<Position, Placement> placementByPosition,
  }) {
    final direction = mainDirection.perpendicular;

    var start = placement.position;
    while (true) {
      final previous = start.translate(-direction.dRow, -direction.dCol);
      if (!board.inBounds(previous) || board.tileAt(previous) == null) break;
      start = previous;
    }

    final letters = StringBuffer();
    var current = start;
    var length = 0;

    while (board.inBounds(current)) {
      final newPlacement = placementByPosition[current];
      final existing = board.tileAt(current);

      if (newPlacement != null) {
        letters.write(newPlacement.letter);
      } else if (existing != null) {
        letters.write(existing.letter);
      } else {
        break;
      }

      length++;
      current = current.translate(direction.dRow, direction.dCol);
    }

    if (length <= 1) return null;

    return _scoreKnownWord(
      board: board,
      word: letters.toString(),
      start: start,
      direction: direction,
      placementByPosition: placementByPosition,
    );
  }
}
