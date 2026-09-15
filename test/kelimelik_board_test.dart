import 'package:test/test.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  group('Kelimelik classic board', () {
    test('contains the complete symmetric premium layout', () {
      final premiums = KelimelikBoard.classicPremiums;

      expect(premiums.length, 49);
      expect(
        premiums.values.where((value) => value == PremiumType.doubleLetter),
        hasLength(24),
      );
      expect(
        premiums.values.where((value) => value == PremiumType.tripleLetter),
        hasLength(8),
      );
      expect(
        premiums.values.where((value) => value == PremiumType.doubleWord),
        hasLength(9),
      );
      expect(
        premiums.values.where((value) => value == PremiumType.tripleWord),
        hasLength(8),
      );
      expect(
        premiums[const Position(7, 7)],
        PremiumType.doubleWord,
      );

      for (final entry in premiums.entries) {
        final mirrored = Position(14 - entry.key.row, 14 - entry.key.col);
        expect(premiums[mirrored], entry.value, reason: '${entry.key}');
      }
    });

    test('adds one random +25 bonus only on a normal cell', () {
      final board = KelimelikBoard.classic(
        bonus25: const Position(7, 6),
      );

      expect(
        board.cellAt(const Position(7, 6)).premium,
        PremiumType.bonus25,
      );
      expect(
        () => KelimelikBoard.classic(bonus25: const Position(7, 7)),
        throwsArgumentError,
      );
      expect(
        () => KelimelikBoard.classic(bonus25: const Position(15, 0)),
        throwsRangeError,
      );
    });

    test('the center star doubles the opening word', () {
      final engine = TrieMoveGenerator(
        dictionary: TrieWordDictionary(['KA']),
      );

      final moves = engine.generate(
        board: KelimelikBoard.classic(),
        rack: const ['K', 'A'],
      );

      expect(moves, isNotEmpty);
      expect(moves.every((move) => move.score == 4), isTrue);
    });
  });
}
