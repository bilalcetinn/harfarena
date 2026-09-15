import '../engine/trie_move_generator.dart';
import '../engine/move_validator.dart';
import '../models/board.dart';
import '../models/generated_move.dart';
import 'move_quality.dart';
import 'position_analysis.dart';

class PositionAnalyzer {
  PositionAnalyzer({
    required this.moveGenerator,
    MoveValidator? moveValidator,
    this.qualityClassifier = const MoveQualityClassifier(),
  }) : moveValidator = moveValidator ??
            MoveValidator(
              dictionary: moveGenerator.dictionary,
              scoreCalculator: moveGenerator.scoreCalculator,
            );

  final TrieMoveGenerator moveGenerator;
  final MoveValidator moveValidator;
  final MoveQualityClassifier qualityClassifier;

  PositionAnalysis analyze({
    required Board board,
    required List<String> rack,
    required GeneratedMove playedMove,
    int topMoveCount = 5,
  }) {
    if (topMoveCount < 1) {
      throw ArgumentError.value(topMoveCount, 'topMoveCount', 'Must be >= 1');
    }

    final verifiedPlayedMove = moveValidator.validateAndScore(
      board: board,
      rack: rack,
      move: playedMove,
    );

    final topMoves = moveGenerator.generate(
      board: board,
      rack: rack,
      limit: topMoveCount,
    );

    if (topMoves.isEmpty) {
      throw StateError('No legal scoring move found for this position.');
    }

    final bestMove = topMoves.first;
    final rawLoss = bestMove.score - verifiedPlayedMove.score;
    final scoreLoss = rawLoss < 0 ? 0 : rawLoss;
    final efficiency = bestMove.score <= 0
        ? 1.0
        : (verifiedPlayedMove.score / bestMove.score)
            .clamp(0.0, 1.0)
            .toDouble();

    return PositionAnalysis(
      playedMove: verifiedPlayedMove,
      bestMove: bestMove,
      topMoves: List<GeneratedMove>.unmodifiable(topMoves),
      scoreLoss: scoreLoss,
      efficiency: efficiency,
      quality: qualityClassifier.classify(
        bestScore: bestMove.score,
        playedScore: verifiedPlayedMove.score,
      ),
    );
  }
}
