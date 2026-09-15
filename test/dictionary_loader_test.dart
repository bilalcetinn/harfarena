import 'package:test/test.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  group('DictionaryLoader', () {
    test('loads the packaged Turkish word list into a Trie', () async {
      final dictionary = await DictionaryLoader.loadTrie('assets/words.txt');

      expect(dictionary.length, 62025);
      expect(dictionary.contains('KALE'), isTrue);
      expect(dictionary.contains('KARTELA'), isTrue);
      expect(dictionary.containsPrefix('KAR'), isTrue);
    });

    test('reports a missing dictionary file clearly', () {
      expect(
        () => DictionaryLoader.loadTrie('assets/missing.txt'),
        throwsArgumentError,
      );
    });
  });
}
