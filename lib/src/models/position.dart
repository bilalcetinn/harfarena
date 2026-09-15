class Position {
  const Position(this.row, this.col);

  final int row;
  final int col;

  Position translate(int dRow, int dCol) => Position(row + dRow, col + dCol);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}
