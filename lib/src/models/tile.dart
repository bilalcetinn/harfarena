class Tile {
  const Tile({required this.letter, this.isBlank = false});

  final String letter;
  final bool isBlank;

  @override
  String toString() => isBlank ? '$letter*' : letter;
}
