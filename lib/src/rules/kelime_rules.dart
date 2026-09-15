class KelimeRules {
  const KelimeRules({
    this.boardSize = 15,
    this.rackSize = 7,
    this.fullRackBonus = 30,
    this.randomBonusPoints = 25,
  });

  final int boardSize;
  final int rackSize;
  final int fullRackBonus;
  final int randomBonusPoints;

  static const Map<String, int> letterPoints = {
    'A': 1,
    'B': 3,
    'C': 4,
    'Ç': 4,
    'D': 3,
    'E': 1,
    'F': 7,
    'G': 5,
    'Ğ': 8,
    'H': 5,
    'I': 2,
    'İ': 1,
    'J': 10,
    'K': 1,
    'L': 1,
    'M': 2,
    'N': 1,
    'O': 2,
    'Ö': 7,
    'P': 5,
    'R': 1,
    'S': 2,
    'Ş': 4,
    'T': 1,
    'U': 2,
    'Ü': 3,
    'V': 7,
    'Y': 3,
    'Z': 4,
  };

  static const Map<String, int> tileCounts = {
    'A': 12,
    'B': 2,
    'C': 2,
    'Ç': 2,
    'D': 2,
    'E': 8,
    'F': 1,
    'G': 1,
    'Ğ': 1,
    'H': 1,
    'I': 4,
    'İ': 7,
    'J': 1,
    'K': 7,
    'L': 7,
    'M': 4,
    'N': 5,
    'O': 3,
    'Ö': 1,
    'P': 1,
    'R': 6,
    'S': 3,
    'Ş': 2,
    'T': 5,
    'U': 3,
    'Ü': 2,
    'V': 1,
    'Y': 2,
    'Z': 2,
    '?': 2,
  };

  int pointsFor(String letter) => letterPoints[letter] ?? 0;
}
