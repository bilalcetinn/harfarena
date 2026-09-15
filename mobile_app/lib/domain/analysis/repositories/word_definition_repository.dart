import 'package:kelime_analiz_mobile/domain/analysis/models/word_definition.dart';

abstract interface class WordDefinitionRepository {
  Future<WordDefinition> lookup(String word);
}
