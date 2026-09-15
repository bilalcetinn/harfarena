import '../models/board.dart';
import '../models/position.dart';
import '../models/premium_type.dart';

/// Kelimelik'in 15x15 klasik tahta düzenini oluşturur.
abstract final class KelimelikBoard {
  static const int size = 15;

  static final Map<Position, PremiumType> classicPremiums =
      Map<Position, PremiumType>.unmodifiable(_classicPremiums);

  /// Klasik tahtayı, varsa oyuna özel rastgele +25 bonusuyla oluşturur.
  static Board classic({Position? bonus25}) {
    final premiums = Map<Position, PremiumType>.of(_classicPremiums);

    if (bonus25 != null) {
      if (!_isInBounds(bonus25)) {
        throw RangeError('Bonus position is outside the 15x15 board: $bonus25');
      }
      if (premiums.containsKey(bonus25)) {
        throw ArgumentError.value(
          bonus25,
          'bonus25',
          'The random bonus must be placed on a normal cell',
        );
      }
      premiums[bonus25] = PremiumType.bonus25;
    }

    return Board.empty(size: size, premiums: premiums);
  }

  static bool _isInBounds(Position position) =>
      position.row >= 0 &&
      position.row < size &&
      position.col >= 0 &&
      position.col < size;

  static final Map<Position, PremiumType> _classicPremiums = {
    // K3
    Position(0, 2): PremiumType.tripleWord,
    Position(0, 12): PremiumType.tripleWord,
    Position(2, 0): PremiumType.tripleWord,
    Position(2, 14): PremiumType.tripleWord,
    Position(12, 0): PremiumType.tripleWord,
    Position(12, 14): PremiumType.tripleWord,
    Position(14, 2): PremiumType.tripleWord,
    Position(14, 12): PremiumType.tripleWord,

    // H3
    Position(1, 1): PremiumType.tripleLetter,
    Position(1, 13): PremiumType.tripleLetter,
    Position(4, 4): PremiumType.tripleLetter,
    Position(4, 10): PremiumType.tripleLetter,
    Position(10, 4): PremiumType.tripleLetter,
    Position(10, 10): PremiumType.tripleLetter,
    Position(13, 1): PremiumType.tripleLetter,
    Position(13, 13): PremiumType.tripleLetter,

    // K2 ve merkez yıldız
    Position(2, 7): PremiumType.doubleWord,
    Position(3, 3): PremiumType.doubleWord,
    Position(3, 11): PremiumType.doubleWord,
    Position(7, 2): PremiumType.doubleWord,
    Position(7, 7): PremiumType.doubleWord,
    Position(7, 12): PremiumType.doubleWord,
    Position(11, 3): PremiumType.doubleWord,
    Position(11, 11): PremiumType.doubleWord,
    Position(12, 7): PremiumType.doubleWord,

    // H2
    Position(0, 5): PremiumType.doubleLetter,
    Position(0, 9): PremiumType.doubleLetter,
    Position(1, 6): PremiumType.doubleLetter,
    Position(1, 8): PremiumType.doubleLetter,
    Position(5, 0): PremiumType.doubleLetter,
    Position(5, 5): PremiumType.doubleLetter,
    Position(5, 9): PremiumType.doubleLetter,
    Position(5, 14): PremiumType.doubleLetter,
    Position(6, 1): PremiumType.doubleLetter,
    Position(6, 6): PremiumType.doubleLetter,
    Position(6, 8): PremiumType.doubleLetter,
    Position(6, 13): PremiumType.doubleLetter,
    Position(8, 1): PremiumType.doubleLetter,
    Position(8, 6): PremiumType.doubleLetter,
    Position(8, 8): PremiumType.doubleLetter,
    Position(8, 13): PremiumType.doubleLetter,
    Position(9, 0): PremiumType.doubleLetter,
    Position(9, 5): PremiumType.doubleLetter,
    Position(9, 9): PremiumType.doubleLetter,
    Position(9, 14): PremiumType.doubleLetter,
    Position(13, 6): PremiumType.doubleLetter,
    Position(13, 8): PremiumType.doubleLetter,
    Position(14, 5): PremiumType.doubleLetter,
    Position(14, 9): PremiumType.doubleLetter,
  };
}
