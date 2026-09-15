import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/ui/analysis/match_analysis_view.dart';
import 'package:kelime_analiz_mobile/domain/analysis/models/word_definition.dart';
import 'package:kelime_analiz_mobile/domain/analysis/repositories/word_definition_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  test('kullanici adi ayni profil koduna eslenir', () {
    expect(profileDocumentCode('Bilal224'), profileDocumentCode('bilal224'));

    expect(profileDocumentCode('Bilal224'), hasLength(8));
  });

  testWidgets('mac analizi tahtada hamle olarak gosterilir', (tester) async {
    const move = GeneratedMove(
      word: 'KA',
      start: Position(7, 7),
      direction: Direction.horizontal,
      placements: [
        Placement(position: Position(7, 7), letter: 'K'),
        Placement(position: Position(7, 8), letter: 'A'),
      ],
      score: 4,
    );

    const position = PositionAnalysis(
      playedMove: move,
      bestMove: move,
      topMoves: [move],
      scoreLoss: 0,
      efficiency: 1,
      quality: MoveQuality.best,
    );

    const report = GameAnalysisReport(
      turns: [position],
      totalScoreLoss: 0,
      averageEfficiency: 1,
      qualityCounts: {MoveQuality.best: 1},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MatchAnalysisScreen(
          initialBoard: KelimelikBoard.classic(),
          turns: const [
            GameTurn(rack: ['K', 'A'], playedMove: move),
          ],
          report: report,
          turnIsMine: const [true],
          myName: 'Bilal',
          opponentName: 'Rakip',
          definitions: _FakeDefinitions(),
        ),
      ),
    );

    expect(find.text('1 / 1. hamle'), findsOneWidget);

    expect(find.text('EN İYİ HAMLE'), findsWidgets);
    expect(find.byIcon(Icons.question_mark_rounded), findsNWidgets(2));
    await tester.ensureVisible(find.byIcon(Icons.question_mark_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.question_mark_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('1. Bir anlam.'), findsOneWidget);
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();

    final bestMoveMessage = find.text('Bu pozisyonda en iyi hamleyi buldun.');
    await tester.dragUntilVisible(
      bestMoveMessage,
      find.byType(ListView),
      const Offset(0, -260),
    );
    expect(bestMoveMessage, findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

class _FakeDefinitions implements WordDefinitionRepository {
  @override
  Future<WordDefinition> lookup(String word) async =>
      WordDefinition(word: word, meanings: const ['Bir anlam.']);
}
