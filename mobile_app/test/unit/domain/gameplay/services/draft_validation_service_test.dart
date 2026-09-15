import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/services/draft_validation_service.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  Placement place(int row, int col, String letter, {bool blank = false}) =>
      Placement(position: Position(row, col), letter: letter, isBlank: blank);

  test('empty draft is neutral', () {
    final result = evaluateDraft(
      board: Board.empty(),
      rack: ['A'],
      placements: [],
      dictionary: SetWordDictionary(['AT']),
    );
    expect(result.isValid, isFalse);
    expect(result.error, isNull);
    expect(result.wordPositions, isEmpty);
  });

  test(
    'a changed tile invalidates its cross word and highlights old letters',
    () {
      final board = Board.empty().withTile(
        const Position(6, 7),
        const Tile(letter: 'K'),
      );
      final dictionary = SetWordDictionary(['AT', 'ET', 'KA']);
      final valid = evaluateDraft(
        board: board,
        rack: ['A', 'T'],
        placements: [place(7, 7, 'A'), place(7, 8, 'T')],
        dictionary: dictionary,
      );
      expect(valid.isValid, isTrue);
      expect(valid.move!.formedWords.map((word) => word.word), ['AT', 'KA']);
      expect(valid.wordPositions, {
        const Position(6, 7),
        const Position(7, 7),
        const Position(7, 8),
      });
      final invalid = evaluateDraft(
        board: board,
        rack: ['E', 'T'],
        placements: [place(7, 7, 'E'), place(7, 8, 'T')],
        dictionary: dictionary,
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.move, isNull);
      expect(invalid.error, contains('“KE” sözlükte bulunamadı.'));
      expect(invalid.wordPositions, {
        const Position(6, 7),
        const Position(7, 7),
      });
    },
  );

  test('gaps between draft tiles fail before dictionary validation', () {
    final result = evaluateDraft(
      board: Board.empty(),
      rack: ['A', 'T'],
      placements: [place(7, 7, 'A'), place(7, 9, 'T')],
      dictionary: SetWordDictionary(['A', 'AT']),
    );
    expect(result.isValid, isFalse);
    expect(result.error, contains('boş kare'));
  });

  for (final direction in Direction.values) {
    test(
      'single tile extends a ${direction.name} word without double scoring',
      () {
        final existing = const Position(
          7,
          7,
        ).translate(-direction.dRow, -direction.dCol);
        final result = evaluateDraft(
          board: Board.empty().withTile(existing, const Tile(letter: 'A')),
          rack: ['T'],
          placements: [place(7, 7, 'T')],
          dictionary: SetWordDictionary(['T', 'AT']),
        );
        expect(result.isValid, isTrue);
        expect(result.move!.word, 'AT');
        expect(result.move!.direction, direction);
        expect(result.move!.score, 2);
        expect(result.move!.formedWords, hasLength(1));
      },
    );
  }

  test(
    'prefix and suffix are part of the word, existing blank remains zero',
    () {
      final board = Board.empty()
          .withTile(const Position(7, 5), const Tile(letter: 'K'))
          .withTile(const Position(7, 6), const Tile(letter: 'A'))
          .withTile(
            const Position(7, 9),
            const Tile(letter: 'M', isBlank: true),
          );
      final result = evaluateDraft(
        board: board,
        rack: ['L', 'E'],
        placements: [place(7, 8, 'E'), place(7, 7, 'L')],
        dictionary: SetWordDictionary(['KALEM']),
      );
      expect(result.isValid, isTrue);
      expect(result.move!.word, 'KALEM');
      expect(result.move!.start, const Position(7, 5));
      expect(result.move!.score, 4);
      expect(result.wordPositions, {
        for (var col = 5; col <= 9; col++) Position(7, col),
      });
    },
  );

  test('a joker uses the blank rack tile and gets zero letter points', () {
    final result = evaluateDraft(
      board: Board.empty(
        premiums: {const Position(7, 7): PremiumType.tripleLetter},
      ),
      rack: ['?', 'T'],
      placements: [place(7, 7, 'A', blank: true), place(7, 8, 'T')],
      dictionary: SetWordDictionary(['AT']),
    );
    expect(result.isValid, isTrue);
    expect(result.move!.score, 1);
    expect(result.move!.placements.first.isBlank, isTrue);
  });

  test('center, connectivity and actual rack are validated by the engine', () {
    final dictionary = SetWordDictionary(['AT']);
    final placements = [place(0, 0, 'A'), place(0, 1, 'T')];
    final offCenter = evaluateDraft(
      board: Board.empty(),
      rack: ['A', 'T'],
      placements: placements,
      dictionary: dictionary,
    );
    expect(offCenter.error, contains('merkez'));
    final disconnected = evaluateDraft(
      board: Board.empty().withTile(
        const Position(7, 7),
        const Tile(letter: 'A'),
      ),
      rack: ['A', 'T'],
      placements: placements,
      dictionary: dictionary,
    );
    expect(disconnected.error, contains('bağlanmalı'));
    final wrongRack = evaluateDraft(
      board: Board.empty(),
      rack: ['A', 'A'],
      placements: [place(7, 7, 'A'), place(7, 8, 'T')],
      dictionary: dictionary,
    );
    expect(wrongRack.error, contains('elindeki harflerle'));
  });

  test(
    'nonlinear, duplicated and occupied draft cells fail without throwing',
    () {
      final dictionary = SetWordDictionary(['AT']);
      for (final placements in [
        [place(7, 7, 'A'), place(8, 8, 'T')],
        [place(7, 7, 'A'), place(7, 7, 'T')],
        [place(-1, 7, 'A')],
      ]) {
        final result = evaluateDraft(
          board: Board.empty(),
          rack: ['A', 'T'],
          placements: placements,
          dictionary: dictionary,
        );
        expect(result.isValid, isFalse);
        expect(result.error, isNotEmpty);
      }
      final occupied = evaluateDraft(
        board: Board.empty().withTile(
          const Position(7, 7),
          const Tile(letter: 'A'),
        ),
        rack: ['T'],
        placements: [place(7, 7, 'T')],
        dictionary: dictionary,
      );
      expect(occupied.error, contains('Dolu'));
    },
  );
}
