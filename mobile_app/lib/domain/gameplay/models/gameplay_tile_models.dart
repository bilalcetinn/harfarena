import 'package:turkish_word_engine/turkish_word_engine.dart';

class GameplayDraftTile {
  const GameplayDraftTile({
    required this.rackIndex,
    required this.letter,
    required this.isBlank,
  });

  final int rackIndex;
  final String letter;
  final bool isBlank;
}

class GameplayTileDragData {
  const GameplayTileDragData({required this.rackIndex, this.origin});

  final int rackIndex;
  final Position? origin;
}
