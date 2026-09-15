import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kelime_analiz_mobile/data/analysis/services/word_definition_service.dart';

void main() {
  test('TDK yanıtındaki anlamları sırasıyla okur', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'sozluk.gov.tr');
      expect(request.url.queryParameters['ara'], 'kalem');
      return http.Response(
        '[{"madde":"kalem","anlamlarListe":[{"anlam":"Yazı aracı"},{"anlam":"Resmî birim"}]}]',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await WordDefinitionService(client: client).lookup('KALEM');

    expect(result.word, 'KALEM');
    expect(result.meanings, ['Yazı aracı', 'Resmî birim']);
  });

  test('sonuç bulunmayan kelimeyi boş anlam listesiyle döndürür', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    final result = await WordDefinitionService(client: client).lookup('YOK');
    expect(result.meanings, isEmpty);
  });
}
