import 'package:kelime_analiz_mobile/domain/analysis/repositories/word_definition_repository.dart';

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kelime_analiz_mobile/domain/analysis/models/word_definition.dart';

class WordDefinitionService implements WordDefinitionRepository {
  WordDefinitionService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = <String, String>{
    'Accept': 'application/json,text/plain,*/*',
    'Accept-Language': 'tr-TR,tr;q=0.9',
    'Referer': 'https://sozluk.gov.tr/',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
  };

  @override
  Future<WordDefinition> lookup(String word) async {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return WordDefinition(word: word, meanings: const []);
    }

    final searchWord = _turkishLower(normalized);

    final uri = Uri.https('sozluk.gov.tr', '/gts', <String, String>{
      'ara': searchWord,
    });

    http.Response? response;
    Object? lastError;

    // TDK zaman zaman ilk istekte geçici hata verebildiği için
    // kısa bir retry yapıyoruz.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          break;
        }

        lastError = StateError('TDK HTTP ${response.statusCode}');
      } on TimeoutException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      } catch (error) {
        lastError = error;
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }

    if (response == null || response.statusCode != 200) {
      throw StateError('TDK sözlüğüne ulaşılamadı: $lastError');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
    } on FormatException {
      // Endpoint normalde JSON döndürür. Beklenmeyen cevapta popup'ın
      // tümünü çökertmek yerine boş anlam listesi döndür.
      return WordDefinition(word: normalized, meanings: const []);
    }

    if (decoded is! List || decoded.isEmpty) {
      return WordDefinition(word: normalized, meanings: const []);
    }

    final meanings = <String>[];

    // Aynı yazılışa ait birden fazla TDK maddesi olabilir (ör. "er").
    // Sadece ilk maddeyi değil, sonuçtaki uygun maddeleri de topla.
    for (final rawEntry in decoded) {
      if (rawEntry is! Map) continue;

      final entry = Map<String, dynamic>.from(rawEntry);

      final rawMeanings = entry['anlamlarListe'];

      if (rawMeanings is! List) continue;

      for (final rawMeaning in rawMeanings) {
        if (rawMeaning is! Map) continue;

        final value = rawMeaning['anlam'];

        if (value is! String) continue;

        final meaning = value.trim();

        if (meaning.isEmpty || meanings.contains(meaning)) {
          continue;
        }

        meanings.add(meaning);

        if (meanings.length >= 5) {
          break;
        }
      }

      if (meanings.length >= 5) {
        break;
      }
    }

    return WordDefinition(
      word: normalized,
      meanings: List<String>.unmodifiable(meanings),
    );
  }

  String _turkishLower(String value) {
    return value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  }
}
