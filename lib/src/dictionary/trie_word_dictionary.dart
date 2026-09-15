import '../rules/turkish_text.dart';
import 'word_dictionary.dart';

class TrieNode {
  final Map<String, TrieNode> children = <String, TrieNode>{};
  bool isWord = false;

  TrieNode? child(String letter) => children[letter];
}

class TrieWordDictionary implements WordDictionary {
  TrieWordDictionary(Iterable<String> source) {
    for (final rawWord in source) {
      final word = tryNormalizeTurkishWord(rawWord);
      if (word == null || !_words.add(word)) continue;

      var node = root;
      for (var i = 0; i < word.length; i++) {
        node = node.children.putIfAbsent(word[i], TrieNode.new);
      }
      node.isWord = true;
    }
  }

  final TrieNode root = TrieNode();
  final Set<String> _words = <String>{};

  @override
  Iterable<String> get words => _words;

  @override
  bool contains(String word) {
    final normalized = tryNormalizeTurkishWord(word);
    if (normalized == null) return false;

    var node = root;
    for (var i = 0; i < normalized.length; i++) {
      final next = node.child(normalized[i]);
      if (next == null) return false;
      node = next;
    }
    return node.isWord;
  }

  bool containsPrefix(String prefix) {
    final normalized = tryNormalizeTurkishWord(prefix);
    if (normalized == null) return false;

    var node = root;
    for (var i = 0; i < normalized.length; i++) {
      final next = node.child(normalized[i]);
      if (next == null) return false;
      node = next;
    }
    return true;
  }

  int get length => _words.length;
}
