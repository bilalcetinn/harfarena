import 'package:test/test.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  group('TrieMoveGenerator equivalence', () {
    test('matches the exhaustive generator on representative positions', () {
      const words = [
        'A',
        'AK',
        'AL',
        'AR',
        'KA',
        'KAL',
        'KALE',
        'KAR',
        'KARE',
        'LA',
      ];
      final setDictionary = SetWordDictionary(words);
      final trieDictionary = TrieWordDictionary(words);
      final exhaustive = MoveGenerator(dictionary: setDictionary);
      final trie = TrieMoveGenerator(dictionary: trieDictionary);

      final positions = <({Board board, List<String> rack})>[
        (board: Board.empty(), rack: const ['K', 'A', 'L', 'E']),
        (
          board: Board.empty().withTile(
            const Position(7, 7),
            const Tile(letter: 'A'),
          ),
          rack: const ['K', 'L', 'E', 'R'],
        ),
        (
          board: Board.empty()
              .withTile(const Position(7, 7), const Tile(letter: 'A'))
              .withTile(const Position(6, 8), const Tile(letter: 'A')),
          rack: const ['K', 'L', '?'],
        ),
      ];

      for (final position in positions) {
        final expected = _canonicalize(
          exhaustive.generate(board: position.board, rack: position.rack),
        );
        final actual = _canonicalize(
          trie.generate(board: position.board, rack: position.rack),
        );

        expect(actual.keys, unorderedEquals(expected.keys));
        for (final key in expected.keys) {
          expect(actual[key]!.score, expected[key]!.score, reason: key);
          expect(
            actual[key]!.formedWords.map((word) => word.word),
            unorderedEquals(
              expected[key]!.formedWords.map((word) => word.word),
            ),
            reason: key,
          );
        }
      }
    });
  });
}

Map<String, GeneratedMove> _canonicalize(List<GeneratedMove> moves) {
  final result = <String, GeneratedMove>{};
  for (final move in moves) {
    final key = '${move.start.row}:${move.start.col}:'
        '${move.direction.name}:${move.word}';
    final previous = result[key];
    if (previous == null || move.score > previous.score) {
      result[key] = move;
    }
  }
  return result;
}
