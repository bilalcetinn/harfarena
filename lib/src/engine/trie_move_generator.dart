import '../dictionary/trie_word_dictionary.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/generated_move.dart';
import '../models/placement.dart';
import '../models/position.dart';
import '../rules/turkish_text.dart';
import 'score_calculator.dart';

/// Trie tabanlı hamle üretici.
///
/// V0.1'deki [MoveGenerator] tüm sözlük kelimelerini tahtanın her yerine
/// deniyordu. Bu üretici ise sözlüğü harf harf gezer ve rack/tahta ile mümkün
/// olmayan dalları erken keser. Ayrıca her boş hücre için perpendicular
/// cross-check harflerini önceden hesaplar.
class TrieMoveGenerator {
  TrieMoveGenerator({
    required this.dictionary,
    this.scoreCalculator = const ScoreCalculator(),
  });

  final TrieWordDictionary dictionary;
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
    final rackCounts = <String, int>{};
    var blanks = 0;

    for (final tile in normalizedRack) {
      if (tile == '?') {
        blanks++;
      } else {
        rackCounts[tile] = (rackCounts[tile] ?? 0) + 1;
      }
    }

    // Aynı board hamlesi blank/normal taş kombinasyonuyla birden fazla kez
    // üretilebilir. Anlık skor analizinde en yüksek skorlu varyantı tutuyoruz.
    final results = <String, GeneratedMove>{};

    for (final direction in Direction.values) {
      final crossChecks = _buildCrossChecks(board, direction);

      for (var row = 0; row < board.size; row++) {
        for (var col = 0; col < board.size; col++) {
          final start = Position(row, col);
          final before = start.translate(-direction.dRow, -direction.dCol);

          // Bir ana kelime mevcut bir harfin ortasından başlayamaz.
          if (board.inBounds(before) && board.tileAt(before) != null) {
            continue;
          }

          _walk(
            board: board,
            direction: direction,
            start: start,
            position: start,
            node: dictionary.root,
            word: '',
            placements: const <Placement>[],
            rackCounts: rackCounts,
            blanksLeft: blanks,
            touchedExisting: false,
            coversCenter: false,
            crossChecks: crossChecks,
            output: results,
          );
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

  void _walk({
    required Board board,
    required Direction direction,
    required Position start,
    required Position position,
    required TrieNode node,
    required String word,
    required List<Placement> placements,
    required Map<String, int> rackCounts,
    required int blanksLeft,
    required bool touchedExisting,
    required bool coversCenter,
    required Map<Position, Set<String>?> crossChecks,
    required Map<String, GeneratedMove> output,
  }) {
    final nextCellIsEmpty =
        !board.inBounds(position) || board.tileAt(position) == null;

    if (node.isWord &&
        placements.isNotEmpty &&
        nextCellIsEmpty &&
        (board.isEmpty ? coversCenter : touchedExisting)) {
      final score = scoreCalculator.calculate(
        board: board,
        word: word,
        start: start,
        direction: direction,
        placements: placements,
      );

      final move = GeneratedMove(
        word: word,
        start: start,
        direction: direction,
        placements: List<Placement>.unmodifiable(placements),
        score: score.total,
        formedWords: score.formedWords,
      );

      final identity = '${start.row}:${start.col}:${direction.name}:$word';
      final previous = output[identity];
      if (previous == null || move.score > previous.score) {
        output[identity] = move;
      }
    }

    if (!board.inBounds(position)) return;

    final existing = board.tileAt(position);
    final nextPosition = position.translate(direction.dRow, direction.dCol);
    final centerCovered = coversCenter || position == board.center;

    if (existing != null) {
      final child = node.child(existing.letter);
      if (child == null) return;

      _walk(
        board: board,
        direction: direction,
        start: start,
        position: nextPosition,
        node: child,
        word: '$word${existing.letter}',
        placements: placements,
        rackCounts: rackCounts,
        blanksLeft: blanksLeft,
        touchedExisting: true,
        coversCenter: centerCovered,
        crossChecks: crossChecks,
        output: output,
      );
      return;
    }

    final allowedLetters = crossChecks[position];

    for (final entry in node.children.entries) {
      final letter = entry.key;
      if (allowedLetters != null && !allowedLetters.contains(letter)) {
        continue;
      }

      final perpendicularTouch = _hasPerpendicularNeighbor(
        board: board,
        position: position,
        mainDirection: direction,
      );

      final available = rackCounts[letter] ?? 0;
      if (available > 0) {
        rackCounts[letter] = available - 1;
        final nextPlacements = <Placement>[
          ...placements,
          Placement(position: position, letter: letter),
        ];

        _walk(
          board: board,
          direction: direction,
          start: start,
          position: nextPosition,
          node: entry.value,
          word: '$word$letter',
          placements: nextPlacements,
          rackCounts: rackCounts,
          blanksLeft: blanksLeft,
          touchedExisting: touchedExisting || perpendicularTouch,
          coversCenter: centerCovered,
          crossChecks: crossChecks,
          output: output,
        );
        rackCounts[letter] = available;
      }

      if (blanksLeft > 0) {
        final nextPlacements = <Placement>[
          ...placements,
          Placement(position: position, letter: letter, isBlank: true),
        ];

        _walk(
          board: board,
          direction: direction,
          start: start,
          position: nextPosition,
          node: entry.value,
          word: '$word$letter',
          placements: nextPlacements,
          rackCounts: rackCounts,
          blanksLeft: blanksLeft - 1,
          touchedExisting: touchedExisting || perpendicularTouch,
          coversCenter: centerCovered,
          crossChecks: crossChecks,
          output: output,
        );
      }
    }
  }

  Map<Position, Set<String>?> _buildCrossChecks(
    Board board,
    Direction mainDirection,
  ) {
    final result = <Position, Set<String>?>{};
    final perpendicular = mainDirection.perpendicular;

    for (var row = 0; row < board.size; row++) {
      for (var col = 0; col < board.size; col++) {
        final position = Position(row, col);
        if (board.tileAt(position) != null) continue;

        final prefix = _lettersBefore(board, position, perpendicular);
        final suffix = _lettersAfter(board, position, perpendicular);

        if (prefix.isEmpty && suffix.isEmpty) {
          result[position] = null; // Her harf cross açısından serbest.
          continue;
        }

        final allowed = <String>{};
        for (var i = 0; i < turkishAlphabet.length; i++) {
          final letter = turkishAlphabet[i];
          if (dictionary.contains('$prefix$letter$suffix')) {
            allowed.add(letter);
          }
        }
        result[position] = allowed;
      }
    }

    return result;
  }

  String _lettersBefore(
    Board board,
    Position position,
    Direction direction,
  ) {
    final letters = <String>[];
    var cursor = position.translate(-direction.dRow, -direction.dCol);

    while (board.inBounds(cursor)) {
      final tile = board.tileAt(cursor);
      if (tile == null) break;
      letters.add(tile.letter);
      cursor = cursor.translate(-direction.dRow, -direction.dCol);
    }

    return letters.reversed.join();
  }

  String _lettersAfter(
    Board board,
    Position position,
    Direction direction,
  ) {
    final letters = StringBuffer();
    var cursor = position.translate(direction.dRow, direction.dCol);

    while (board.inBounds(cursor)) {
      final tile = board.tileAt(cursor);
      if (tile == null) break;
      letters.write(tile.letter);
      cursor = cursor.translate(direction.dRow, direction.dCol);
    }

    return letters.toString();
  }

  bool _hasPerpendicularNeighbor({
    required Board board,
    required Position position,
    required Direction mainDirection,
  }) {
    final direction = mainDirection.perpendicular;
    final before = position.translate(-direction.dRow, -direction.dCol);
    final after = position.translate(direction.dRow, direction.dCol);

    return (board.inBounds(before) && board.tileAt(before) != null) ||
        (board.inBounds(after) && board.tileAt(after) != null);
  }
}
