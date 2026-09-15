enum Direction { horizontal, vertical }

extension DirectionX on Direction {
  int get dRow => this == Direction.horizontal ? 0 : 1;
  int get dCol => this == Direction.horizontal ? 1 : 0;

  Direction get perpendicular =>
      this == Direction.horizontal ? Direction.vertical : Direction.horizontal;
}
