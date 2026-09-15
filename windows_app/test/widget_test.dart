import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz/main.dart';

void main() {
  testWidgets('ana analiz ekrani acilir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const KelimeAnalizApp());
    await tester.pump();

    expect(find.text('Kelime Analiz'), findsOneWidget);
    expect(find.text('Eldeki Harfler'), findsOneWidget);
    expect(find.text('ANALİZ ET'), findsOneWidget);
    expect(find.text('En İyi Hamleler'), findsOneWidget);
  });
}
