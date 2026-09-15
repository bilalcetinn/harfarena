import 'generated_move.dart';
import 'position.dart';
import 'premium_type.dart';
import 'tile.dart';

class BoardCell {
  const BoardCell({this.tile, this.premium = PremiumType.none});

  final Tile? tile;
  final PremiumType premium;

  BoardCell copyWith(
      {Tile? tile, bool clearTile = false, PremiumType? premium}) {
    return BoardCell(
      tile: clearTile ? null : (tile ?? this.tile),
      premium: premium ?? this.premium,
    );
  }
}

class Board {
  Board._(this.size, this._cells);

  factory Board.empty({
    int size = 15,
    Map<Position, PremiumType> premiums = const {},
  }) {
    final cells = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => BoardCell(
          premium: premiums[Position(row, col)] ?? PremiumType.none,
        ),
        growable: false,
      ),
      growable: false,
    );
    return Board._(size, cells);
  }

  final int size;
  final List<List<BoardCell>> _cells;

  bool inBounds(Position position) =>
      position.row >= 0 &&
      position.row < size &&
      position.col >= 0 &&
      position.col < size;

  BoardCell cellAt(Position position) {
    if (!inBounds(position)) {
      throw RangeError('Position is outside board: $position');
    }
    return _cells[position.row][position.col];
  }

  Tile? tileAt(Position position) => cellAt(position).tile;

  bool get isEmpty {
    for (final row in _cells) {
      for (final cell in row) {
        if (cell.tile != null) return false;
      }
    }
    return true;
  }

  Position get center => Position(size ~/ 2, size ~/ 2);

  Board withTile(Position position, Tile tile) {
    final copied = _copyCells();
    copied[position.row][position.col] =
        copied[position.row][position.col].copyWith(
      tile: tile,
    );
    return Board._(size, copied);
  }

  Board applyMove(GeneratedMove move) {
    final seen = <Position>{};
    final invalid = <Position>[];
    for (final placement in move.placements) {
      if (!inBounds(placement.position) ||
          !seen.add(placement.position) ||
          tileAt(placement.position) != null) {
        invalid.add(placement.position);
      }
    }
    if (invalid.isNotEmpty) {
      throw StateError(
        'Move contains out-of-bounds, duplicate, or occupied placements: '
        '$invalid',
      );
    }

    var result = this;
    for (final placement in move.placements) {
      result = result.withTile(
        placement.position,
        Tile(letter: placement.letter, isBlank: placement.isBlank),
      );
    }
    return result;
  }

  List<List<BoardCell>> _copyCells() => List.generate(
        size,
        (row) => List<BoardCell>.from(_cells[row], growable: false),
        growable: false,
      );
}
