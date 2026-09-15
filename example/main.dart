import 'package:turkish_word_engine/turkish_word_engine.dart';

Future<void> main() async {
  final loadWatch = Stopwatch()..start();
  final dictionary = await DictionaryLoader.loadTrie('assets/words.txt');
  loadWatch.stop();

  final board = KelimelikBoard.classic();

  final engine = TrieMoveGenerator(dictionary: dictionary);
  final moveWatch = Stopwatch()..start();
  final moves = engine.generate(
    board: board,
    rack: const ['K', 'A', 'L', 'E', 'R', 'T', 'A'],
    limit: 10,
  );
  moveWatch.stop();

  print(
    '${dictionary.length} kelime ${loadWatch.elapsedMilliseconds} ms içinde '
    'yüklendi.',
  );
  print('En iyi hamleler ${moveWatch.elapsedMilliseconds} ms içinde bulundu:');

  for (final move in moves) {
    print(move);
  }
}
