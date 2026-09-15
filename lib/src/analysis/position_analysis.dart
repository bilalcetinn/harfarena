import '../models/generated_move.dart';
import 'move_quality.dart';

class PositionAnalysis {
  const PositionAnalysis({
    required this.playedMove,
    required this.bestMove,
    required this.topMoves,
    required this.scoreLoss,
    required this.efficiency,
    required this.quality,
  });

  final GeneratedMove playedMove;
  final GeneratedMove bestMove;
  final List<GeneratedMove> topMoves;
  final int scoreLoss;

  /// 0.0 - 1.0 aralığında, yalnızca anlık puana dayalı verimlilik.
  final double efficiency;
  final MoveQuality quality;
}
