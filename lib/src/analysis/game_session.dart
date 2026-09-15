import '../models/board.dart';
import '../models/generated_move.dart';
import 'game_analysis.dart';
import 'position_analyzer.dart';
import '../rules/kelimelik_board.dart';
import '../rules/kelime_rules.dart';
import '../models/tile_bag.dart';

/// Oyunun kendisi ile analiz ekranı arasında ortak, kayıpsız veri katmanı.
///
/// Oyun sırasında her turda kullanılan rack ve oynanan hamle saklanır. Böylece
/// maç sonunda ekran görüntüsü veya OCR gerekmeden aynı pozisyonlar yeniden
/// oluşturulup [analyze] ile karşılaştırılabilir.
class GameSession {
  GameSession._({
    required this.initialBoard,
    required this.currentBoard,
    required List<String> rack,
    required List<GameTurn> turns,
  })  : rack = List<String>.unmodifiable(rack),
        turns = List<GameTurn>.unmodifiable(turns);

  factory GameSession.newGame({Board? board, List<String> rack = const []}) {
    final initial = board ?? KelimelikBoard.classic();
    return GameSession._(
      initialBoard: initial,
      currentBoard: initial,
      rack: rack,
      turns: const [],
    );
  }

  final Board initialBoard;
  final Board currentBoard;
  /// Oyuncunun o an elinde bulunan taşlar. Yeni oyun başında bir kez verilir.
  final List<String> rack;
  final List<GameTurn> turns;

  int get turnCount => turns.length;

  /// Hamleyi uygular ve yeni oturum durumunu döndürür.
  /// Board.applyMove, dolu kare/tekrar/tahta dışı hamleleri reddeder.
  GameSession play({
    required List<String> rack,
    required GeneratedMove move,
    List<String> drawnTiles = const [],
  }) {
    final nextBoard = currentBoard.applyMove(move);
    final nextRack = List<String>.from(rack);
    for (final placement in move.placements) {
      final tile = placement.isBlank ? '?' : placement.letter;
      final index = nextRack.indexOf(tile);
      if (index >= 0) nextRack.removeAt(index);
    }
    nextRack.addAll(drawnTiles);
    return GameSession._(
      initialBoard: initialBoard,
      currentBoard: nextBoard,
      rack: nextRack,
      turns: [...turns, GameTurn(rack: List<String>.from(rack), playedMove: move)],
    );
  }

  /// Hamleyi oynar ve rack'i tekrar yedi taşa tamamlar.
  GameSession playAndRefill({
    required List<String> rack,
    required GeneratedMove move,
    required TileBag bag,
  }) {
    final afterMove = play(rack: rack, move: move);
    final needed = KelimeRules().rackSize - afterMove.rack.length;
    return GameSession._(
      initialBoard: afterMove.initialBoard,
      currentBoard: afterMove.currentBoard,
      rack: [...afterMove.rack, ...bag.draw(needed)],
      turns: afterMove.turns,
    );
  }

  GameAnalysisReport analyze({
    required PositionAnalyzer positionAnalyzer,
    int topMoveCount = 5,
  }) {
    return GameAnalyzer(positionAnalyzer: positionAnalyzer).analyze(
      initialBoard: initialBoard,
      turns: turns,
      topMoveCount: topMoveCount,
    );
  }
}
