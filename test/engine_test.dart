import 'package:test/test.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  group('Kelimelik-compatible scoring basics', () {
    test('official letter values are represented', () {
      const rules = KelimeRules();
      expect(rules.pointsFor('A'), 1);
      expect(rules.pointsFor('Ğ'), 8);
      expect(rules.pointsFor('J'), 10);
      expect(rules.pointsFor('Z'), 4);
    });

    test('first move must pass through center', () {
      final dictionary = SetWordDictionary(['KALE']);
      final engine = MoveGenerator(dictionary: dictionary);
      final board = Board.empty();

      final moves = engine.generate(
        board: board,
        rack: const ['K', 'A', 'L', 'E'],
      );

      expect(moves, isNotEmpty);
      expect(
        moves.every((move) {
          for (var i = 0; i < move.word.length; i++) {
            final p = move.start.translate(
              move.direction.dRow * i,
              move.direction.dCol * i,
            );
            if (p == board.center) return true;
          }
          return false;
        }),
        isTrue,
      );
    });

    test('double-word premium applies only to newly placed tile', () {
      final dictionary = SetWordDictionary(['KALE']);
      final engine = MoveGenerator(dictionary: dictionary);
      final board = Board.empty(
        premiums: {const Position(7, 7): PremiumType.doubleWord},
      );

      final moves = engine.generate(
        board: board,
        rack: const ['K', 'A', 'L', 'E'],
      );

      expect(moves.first.score, 8);
    });

    test('blank tile scores zero for the substituted letter', () {
      final dictionary = SetWordDictionary(['JAZ']);
      final engine = MoveGenerator(dictionary: dictionary);
      final board = Board.empty();

      final moves = engine.generate(
        board: board,
        rack: const ['?', 'A', 'Z'],
      );

      expect(moves.first.score, 5);
      expect(
        moves.first.placements.any((p) => p.letter == 'J' && p.isBlank),
        isTrue,
      );
    });

    test('using seven rack tiles adds 30 points', () {
      final dictionary = SetWordDictionary(['KARTELA']);
      final engine = MoveGenerator(dictionary: dictionary);
      final board = Board.empty();

      final moves = engine.generate(
        board: board,
        rack: const ['K', 'A', 'R', 'T', 'E', 'L', 'A'],
      );

      expect(moves.first.score, 37);
    });

    test('new-tile premiums apply to both a main word and its cross word', () {
      final board = Board.empty(
        premiums: {const Position(7, 7): PremiumType.doubleWord},
      )
          .withTile(const Position(7, 8), const Tile(letter: 'A'))
          .withTile(const Position(6, 7), const Tile(letter: 'A'));

      final score = const ScoreCalculator().calculate(
        board: board,
        word: 'KA',
        start: const Position(7, 7),
        direction: Direction.horizontal,
        placements: const [
          Placement(position: Position(7, 7), letter: 'K'),
        ],
      );

      expect(score.total, 8);
      expect(score.formedWords.map((word) => word.word), ['KA', 'AK']);
      expect(score.formedWords.map((word) => word.score), [4, 4]);
    });

    test('letter, word and random bonuses use the tile values correctly', () {
      const calculator = ScoreCalculator();
      const placement = Placement(position: Position(7, 7), letter: 'Ğ');

      int scoreFor(PremiumType premium) => calculator.calculate(
            board: Board.empty(premiums: {const Position(7, 7): premium}),
            word: 'Ğ',
            start: const Position(7, 7),
            direction: Direction.horizontal,
            placements: const [placement],
          ).total;

      expect(scoreFor(PremiumType.doubleLetter), 16);
      expect(scoreFor(PremiumType.tripleLetter), 24);
      expect(scoreFor(PremiumType.doubleWord), 16);
      expect(scoreFor(PremiumType.tripleWord), 24);
      expect(scoreFor(PremiumType.bonus25), 33);
    });

    test('a premium square is not counted again under an existing tile', () {
      final board = Board.empty(
        premiums: {const Position(7, 7): PremiumType.tripleLetter},
      ).withTile(const Position(7, 7), const Tile(letter: 'Ğ'));

      final score = const ScoreCalculator().calculate(
        board: board,
        word: 'ĞA',
        start: const Position(7, 7),
        direction: Direction.horizontal,
        placements: const [
          Placement(position: Position(7, 8), letter: 'A'),
        ],
      );

      expect(score.total, 9);
    });
  });

  group('Trie dictionary and generator', () {
    test('trie normalizes Turkish words and prefixes', () {
      final dictionary = TrieWordDictionary(['kale', 'şeker']);

      expect(dictionary.contains('KALE'), isTrue);
      expect(dictionary.contains('ŞEKER'), isTrue);
      expect(dictionary.containsPrefix('ŞE'), isTrue);
      expect(dictionary.containsPrefix('XYZ'), isFalse);
    });

    test('trie generator finds first move through center', () {
      final dictionary = TrieWordDictionary(['KALE', 'ELA', 'KARE']);
      final engine = TrieMoveGenerator(dictionary: dictionary);
      final board = Board.empty();

      final moves = engine.generate(
        board: board,
        rack: const ['K', 'A', 'L', 'E', 'R'],
      );

      expect(moves, isNotEmpty);
      expect(
        moves.every((move) {
          for (var i = 0; i < move.word.length; i++) {
            final position = move.start.translate(
              move.direction.dRow * i,
              move.direction.dCol * i,
            );
            if (position == board.center) return true;
          }
          return false;
        }),
        isTrue,
      );
    });

    test('trie generator can extend an existing word', () {
      final dictionary = TrieWordDictionary(['KAR', 'KARE']);
      final engine = TrieMoveGenerator(dictionary: dictionary);
      var board = Board.empty();

      board = board
          .withTile(const Position(7, 6), const Tile(letter: 'K'))
          .withTile(const Position(7, 7), const Tile(letter: 'A'))
          .withTile(const Position(7, 8), const Tile(letter: 'R'));

      final moves = engine.generate(board: board, rack: const ['E']);

      expect(
        moves.any(
          (move) =>
              move.word == 'KARE' &&
              move.start == const Position(7, 6) &&
              move.direction == Direction.horizontal,
        ),
        isTrue,
      );
    });

    test('trie generator respects perpendicular cross words', () {
      final dictionary = TrieWordDictionary(['KA', 'AK']);
      final engine = TrieMoveGenerator(dictionary: dictionary);
      var board = Board.empty();

      board = board.withTile(const Position(7, 7), const Tile(letter: 'A'));
      board = board.withTile(const Position(6, 8), const Tile(letter: 'A'));

      final moves = engine.generate(board: board, rack: const ['K']);

      expect(
        moves.any(
          (move) => move.placements.any(
            (p) => p.position == const Position(7, 8) && p.letter == 'K',
          ),
        ),
        isTrue,
      );
    });

    test('generators reject a negative result limit', () {
      final setGenerator = MoveGenerator(
        dictionary: SetWordDictionary(['KA']),
      );
      final trieGenerator = TrieMoveGenerator(
        dictionary: TrieWordDictionary(['KA']),
      );

      expect(
        () => setGenerator.generate(
          board: Board.empty(),
          rack: const ['K', 'A'],
          limit: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => trieGenerator.generate(
          board: Board.empty(),
          rack: const ['K', 'A'],
          limit: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Stockfish-style score analysis', () {
    test('classifies score loss', () {
      const classifier = MoveQualityClassifier();

      expect(
        classifier.classify(bestScore: 60, playedScore: 60),
        MoveQuality.best,
      );
      expect(
        classifier.classify(bestScore: 60, playedScore: 30),
        MoveQuality.mistake,
      );
      expect(
        classifier.classify(bestScore: 90, playedScore: 30),
        MoveQuality.blunder,
      );
    });

    test('recalculates the submitted move score before analysis', () {
      final engine = TrieMoveGenerator(
        dictionary: TrieWordDictionary(['KA', 'AK']),
      );
      final analyzer = PositionAnalyzer(moveGenerator: engine);
      const submittedMove = GeneratedMove(
        word: 'KA',
        start: Position(7, 7),
        direction: Direction.horizontal,
        placements: [
          Placement(position: Position(7, 7), letter: 'K'),
          Placement(position: Position(7, 8), letter: 'A'),
        ],
        score: 999,
      );

      final analysis = analyzer.analyze(
        board: KelimelikBoard.classic(),
        rack: const ['K', 'A'],
        playedMove: submittedMove,
      );

      expect(analysis.playedMove.score, 4);
      expect(analysis.scoreLoss, 0);
      expect(analysis.efficiency, 1);
      expect(analysis.quality, MoveQuality.best);
    });

    test('rejects an illegal submitted move', () {
      final engine = TrieMoveGenerator(
        dictionary: TrieWordDictionary(['KA']),
      );
      final analyzer = PositionAnalyzer(moveGenerator: engine);
      const offCenterMove = GeneratedMove(
        word: 'KA',
        start: Position(0, 0),
        direction: Direction.horizontal,
        placements: [
          Placement(position: Position(0, 0), letter: 'K'),
          Placement(position: Position(0, 1), letter: 'A'),
        ],
        score: 2,
      );

      expect(
        () => analyzer.analyze(
          board: KelimelikBoard.classic(),
          rack: const ['K', 'A'],
          playedMove: offCenterMove,
        ),
        throwsArgumentError,
      );
    });

    test('board refuses to overwrite a tile when applying a move', () {
      final board = Board.empty().withTile(
        const Position(7, 7),
        const Tile(letter: 'A'),
      );
      const invalidMove = GeneratedMove(
        word: 'KA',
        start: Position(7, 6),
        direction: Direction.horizontal,
        placements: [
          Placement(position: Position(7, 7), letter: 'K'),
        ],
        score: 2,
      );

      expect(() => board.applyMove(invalidMove), throwsStateError);
    });

    test('board refuses duplicate placements in a move', () {
      const invalidMove = GeneratedMove(
        word: 'KA',
        start: Position(7, 7),
        direction: Direction.horizontal,
        placements: [
          Placement(position: Position(7, 7), letter: 'K'),
          Placement(position: Position(7, 7), letter: 'A'),
        ],
        score: 2,
      );

      expect(() => Board.empty().applyMove(invalidMove), throwsStateError);
    });
  });
}
