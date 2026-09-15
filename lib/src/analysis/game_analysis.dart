import '../models/board.dart';
import '../models/generated_move.dart';
import 'move_quality.dart';
import 'position_analysis.dart';
import 'position_analyzer.dart';

class GameTurn {
  const GameTurn({
    required this.rack,
    required this.playedMove,
  });

  final List<String> rack;
  final GeneratedMove playedMove;
}

class GameAnalysisReport {
  const GameAnalysisReport({
    required this.turns,
    required this.totalScoreLoss,
    required this.averageEfficiency,
    required this.qualityCounts,
  });

  final List<PositionAnalysis> turns;
  final int totalScoreLoss;
  final double averageEfficiency;
  final Map<MoveQuality, int> qualityCounts;
}

class GameAnalyzer {
  GameAnalyzer({required this.positionAnalyzer});

  final PositionAnalyzer positionAnalyzer;

  GameAnalysisReport analyze({
    required Board initialBoard,
    required List<GameTurn> turns,
    int topMoveCount = 5,
  }) {
    var board = initialBoard;
    final analyses = <PositionAnalysis>[];
    final counts = <MoveQuality, int>{
      for (final quality in MoveQuality.values) quality: 0,
    };
    var totalLoss = 0;
    var efficiencyTotal = 0.0;

    for (final turn in turns) {
      final analysis = positionAnalyzer.analyze(
        board: board,
        rack: turn.rack,
        playedMove: turn.playedMove,
        topMoveCount: topMoveCount,
      );

      analyses.add(analysis);
      totalLoss += analysis.scoreLoss;
      efficiencyTotal += analysis.efficiency;
      counts[analysis.quality] = (counts[analysis.quality] ?? 0) + 1;

      board = board.applyMove(turn.playedMove);
    }

    final averageEfficiency =
        analyses.isEmpty ? 1.0 : efficiencyTotal / analyses.length;

    return GameAnalysisReport(
      turns: List<PositionAnalysis>.unmodifiable(analyses),
      totalScoreLoss: totalLoss,
      averageEfficiency: averageEfficiency,
      qualityCounts: Map<MoveQuality, int>.unmodifiable(counts),
    );
  }
}
