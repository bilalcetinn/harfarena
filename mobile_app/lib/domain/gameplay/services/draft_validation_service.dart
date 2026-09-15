import 'package:turkish_word_engine/turkish_word_engine.dart';

/// One result shared by the live board preview and the submit action.
class DraftValidation {
  DraftValidation({
    this.move,
    this.error,
    Set<Position> wordPositions = const {},
  }) : wordPositions = Set.unmodifiable(wordPositions);

  final GeneratedMove? move;
  final String? error;

  /// Preview'da çerçevelenecek hücreler.
  ///
  /// Geçerli hamlede oluşan kelimelerin tamamını,
  /// geçersiz hamlede ise geçersiz olan kelimelerin tamamını içerir.
  final Set<Position> wordPositions;

  bool get isValid => move != null && error == null;
}

class _DraftWord {
  const _DraftWord({required this.word, required this.positions});

  final String word;
  final List<Position> positions;
}

DraftValidation evaluateDraft({
  required Board board,
  required List<String> rack,
  required List<Placement> placements,
  required WordDictionary dictionary,
}) {
  if (placements.isEmpty) return DraftValidation();

  final placedPositions = placements
      .map((placement) => placement.position)
      .toSet();

  DraftValidation invalid(String message, {Set<Position>? positions}) {
    return DraftValidation(
      error: message,
      wordPositions: positions ?? placedPositions,
    );
  }

  final byPosition = <Position, Placement>{};

  for (final placement in placements) {
    if (!board.inBounds(placement.position)) {
      return invalid('Taşları tahtanın içine yerleştir.');
    }

    if (byPosition.containsKey(placement.position)) {
      return invalid('Aynı kareye birden fazla taş koyamazsın.');
    }

    if (board.tileAt(placement.position) != null) {
      return invalid('Dolu bir kareye taş koyamazsın.');
    }

    final letter = tryNormalizeTurkishWord(placement.letter);

    if (letter == null || letter.length != 1) {
      return invalid(
        'Her taş için geçerli bir harf seç; jokerin harfini belirle.',
      );
    }

    byPosition[placement.position] = Placement(
      position: placement.position,
      letter: letter,
      isBlank: placement.isBlank,
    );
  }

  String? letterAt(Position position) {
    if (!board.inBounds(position)) return null;

    return byPosition[position]?.letter ?? board.tileAt(position)?.letter;
  }

  List<Position> lineThrough(Position position, Direction direction) {
    var start = position;

    while (true) {
      final previous = start.translate(-direction.dRow, -direction.dCol);

      if (letterAt(previous) == null) break;
      start = previous;
    }

    final result = <Position>[];
    var current = start;

    while (letterAt(current) != null) {
      result.add(current);
      current = current.translate(direction.dRow, direction.dCol);
    }

    return result;
  }

  String wordForPositions(Iterable<Position> positions) {
    return positions.map(letterAt).join();
  }

  // Tahtada zaten harf varsa yeni hamle mevcut taşlara bağlanmalı.
  // Bu kontrol sözlük kontrolünden önce yapılır.
  var boardHasTiles = false;

  for (var row = 0; row < 15 && !boardHasTiles; row++) {
    for (var col = 0; col < 15; col++) {
      if (board.tileAt(Position(row, col)) != null) {
        boardHasTiles = true;
        break;
      }
    }
  }

  if (boardHasTiles) {
    var connectsToExistingTile = false;

    for (final position in byPosition.keys) {
      final neighbours = <Position>[
        Position(position.row - 1, position.col),
        Position(position.row + 1, position.col),
        Position(position.row, position.col - 1),
        Position(position.row, position.col + 1),
      ];

      if (neighbours.any(
        (neighbour) =>
            board.inBounds(neighbour) && board.tileAt(neighbour) != null,
      )) {
        connectsToExistingTile = true;
        break;
      }
    }

    if (!connectsToExistingTile) {
      return invalid(
        'Kelime tahtadaki harflere bağlanmalı.',
        positions: byPosition.keys.toSet(),
      );
    }
  }

  final first = byPosition.keys.first;

  final directions = Direction.values.where((direction) {
    return byPosition.keys.every(
      (position) => direction == Direction.horizontal
          ? position.row == first.row
          : position.col == first.col,
    );
  }).toList();

  if (directions.isEmpty) {
    return invalid('Bütün taşlar aynı satırda veya aynı sütunda olmalı.');
  }

  final candidates = <GeneratedMove>[];

  for (final direction in directions) {
    final line = lineThrough(first, direction);

    if (!byPosition.keys.every(line.contains)) {
      return invalid('Kelimenin harfleri arasında boş kare kalmamalı.');
    }

    candidates.add(
      GeneratedMove(
        word: wordForPositions(line),
        start: line.first,
        direction: direction,
        placements: List.unmodifiable(byPosition.values),
        score: 0,
      ),
    );
  }

  // Tek yeni taşta yatay ve dikey adaylardan gerçek kelime oluşturanları tut.
  if (candidates.any((candidate) => candidate.word.length > 1)) {
    candidates.removeWhere((candidate) => candidate.word.length == 1);
  }

  candidates.sort((a, b) => b.word.length.compareTo(a.word.length));

  // Yeni taşların oluşturduğu TÜM kelimeleri topla:
  // ana kelime + her yeni taşın çapraz kelimesi.
  final formedWords = <String, _DraftWord>{};

  for (final placement in byPosition.values) {
    for (final direction in Direction.values) {
      final positions = lineThrough(placement.position, direction);

      if (positions.length <= 1) continue;

      final key = positions
          .map((position) => '${position.row}:${position.col}')
          .join('|');

      formedWords[key] = _DraftWord(
        word: wordForPositions(positions),
        positions: positions,
      );
    }
  }

  // Sözlükte olmayan bütün kelimeleri aynı anda bul.
  // Böylece örneğin OA ve Aİ aynı hamlede hatalıysa ikisi de kırmızı olur.
  final invalidWords = <_DraftWord>[];

  for (final formed in formedWords.values) {
    if (!_dictionaryContains(dictionary, formed.word)) {
      invalidWords.add(formed);
    }
  }

  if (invalidWords.isNotEmpty) {
    final invalidPositions = <Position>{};

    for (final invalidWord in invalidWords) {
      invalidPositions.addAll(invalidWord.positions);
    }

    final uniqueWords = <String>[];

    for (final invalidWord in invalidWords) {
      if (!uniqueWords.contains(invalidWord.word)) {
        uniqueWords.add(invalidWord.word);
      }
    }

    final quotedWords = uniqueWords.map((word) => '“$word”').join(', ');

    return invalid(
      uniqueWords.length == 1
          ? '$quotedWords sözlükte bulunamadı.'
          : '$quotedWords sözlükte bulunamadı.',
      positions: invalidPositions,
    );
  }

  final validator = MoveValidator(dictionary: dictionary);

  String? firstError;
  Set<Position>? firstErrorPositions;

  for (final candidate in candidates) {
    try {
      final verified = validator.validateAndScore(
        board: board,
        rack: rack,
        move: candidate,
      );

      final validHighlighted = <Position>{};

      for (final formed in formedWords.values) {
        validHighlighted.addAll(formed.positions);
      }

      // Nadir durumda formedWords boşsa ana adayın hücrelerini yine göster.
      if (validHighlighted.isEmpty) {
        validHighlighted.addAll(
          lineThrough(candidate.start, candidate.direction),
        );
      }

      return DraftValidation(move: verified, wordPositions: validHighlighted);
    } on ArgumentError catch (error) {
      if (firstError != null) continue;

      firstError = _friendlyError(error, candidate.word);

      final rawMessage = '${error.message}';

      if (rawMessage.contains('Word is not valid')) {
        firstErrorPositions = lineThrough(
          candidate.start,
          candidate.direction,
        ).toSet();
      } else {
        firstErrorPositions = byPosition.keys.toSet();
      }
    }
  }

  return invalid(
    firstError ?? 'Taşlarla geçerli bir kelime oluştur.',
    positions: firstErrorPositions,
  );
}

/// WordDictionary sürümleri arasında lookup adının değişebilmesine karşı
/// birkaç yaygın API adını destekler.
///
/// Mevcut engine sürümünde bunlardan biri bulunacaktır.
bool _dictionaryContains(WordDictionary dictionary, String word) {
  final normalized = tryNormalizeTurkishWord(word) ?? word;

  final dynamic source = dictionary;

  try {
    final result = source.contains(normalized);
    if (result is bool) return result;
  } on NoSuchMethodError {
    // Sonraki API adını dene.
  }

  try {
    final result = source.containsWord(normalized);
    if (result is bool) return result;
  } on NoSuchMethodError {
    // Sonraki API adını dene.
  }

  try {
    final result = source.isWord(normalized);
    if (result is bool) return result;
  } on NoSuchMethodError {
    // Sonraki API adını dene.
  }

  try {
    final result = source.isValidWord(normalized);
    if (result is bool) return result;
  } on NoSuchMethodError {
    // Engine API'si beklenmeyen bir isim kullanıyor.
  }

  throw StateError('WordDictionary kelime kontrol metodu bulunamadı.');
}

String _friendlyError(ArgumentError error, String word) {
  final message = '${error.message}';

  if (message.contains('Word is not valid')) {
    return '“$word” sözlükte bulunamadı.';
  }

  if (message.contains('Invalid cross word:')) {
    final crossWord = message.split('Invalid cross word:').last.trim();

    return 'Oluşan yan kelime “$crossWord” sözlükte bulunamadı.';
  }

  if (message.contains('first word must cover center')) {
    return 'İlk kelime merkez karesinden geçmeli.';
  }

  if (message.contains('connect to an existing tile')) {
    return 'Kelime tahtadaki harflere bağlanmalı.';
  }

  if (message.contains('Rack does not contain')) {
    return 'Yerleştirdiğin taşlar elindeki harflerle uyuşmuyor.';
  }

  if (message.contains('Rack cannot contain more')) {
    return 'Elde en fazla yedi taş olabilir.';
  }

  if (message.contains('Invalid rack letter')) {
    return 'Elindeki harfler okunamadı; oyunu yeniden aç.';
  }

  return 'Taşları boşluk bırakmadan, aynı satırda veya sütunda yerleştir.';
}
