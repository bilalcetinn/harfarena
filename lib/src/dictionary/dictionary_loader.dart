import 'dart:io';

import 'trie_word_dictionary.dart';

/// UTF-8, satır başına bir kelime içeren sözlük dosyalarını yükler.
abstract final class DictionaryLoader {
  static Future<TrieWordDictionary> loadTrie(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError.value(path, 'path', 'Dictionary file not found');
    }

    return TrieWordDictionary(await file.readAsLines());
  }
}
