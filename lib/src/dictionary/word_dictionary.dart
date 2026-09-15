abstract interface class WordDictionary {
  Iterable<String> get words;

  bool contains(String word);
}
