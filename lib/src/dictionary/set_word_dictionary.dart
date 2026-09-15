import '../rules/turkish_text.dart';
import 'word_dictionary.dart';

class SetWordDictionary implements WordDictionary {
  SetWordDictionary(Iterable<String> source) : _words = _normalizeWords(source);

  final Set<String> _words;

  static Set<String> _normalizeWords(Iterable<String> source) {
    final result = <String>{};
    for (final word in source) {
      final normalized = tryNormalizeTurkishWord(word);
      if (normalized != null) {
        result.add(normalized);
      }
    }
    return result;
  }

  @override
  Iterable<String> get words => _words;

  @override
  bool contains(String word) {
    final normalized = tryNormalizeTurkishWord(word);
    return normalized != null && _words.contains(normalized);
  }

  int get length => _words.length;
}
