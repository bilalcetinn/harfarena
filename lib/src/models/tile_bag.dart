import 'dart:math';

import '../rules/kelime_rules.dart';

/// Kelime oyununun standart Türkçe taş torbası.
class TileBag {
  TileBag({Random? random, List<String>? tiles})
      : _random = random ?? Random(),
        _tiles = List<String>.from(tiles ?? _buildTiles()) {
    _tiles.shuffle(_random);
  }

  final Random _random;
  final List<String> _tiles;

  int get remaining => _tiles.length;
  bool get isEmpty => _tiles.isEmpty;

  List<String> draw(int count) {
    if (count <= 0 || _tiles.isEmpty) return const [];
    final actual = min(count, _tiles.length);
    return List<String>.generate(actual, (_) => _tiles.removeLast());
  }

  /// Seçilen taşları torbaya geri koyar, karıştırır ve aynı sayıda taş çeker.
  List<String> exchange(Iterable<String> returnedTiles) {
    final returned = List<String>.from(returnedTiles);
    if (returned.isEmpty) return const [];
    if (_tiles.length < returned.length) {
      throw StateError('Torbada değişim için yeterli taş yok.');
    }
    _tiles.addAll(returned);
    _tiles.shuffle(_random);
    return draw(returned.length);
  }

  static List<String> _buildTiles() {
    final tiles = <String>[];
    for (final entry in KelimeRules.tileCounts.entries) {
      tiles.addAll(List<String>.filled(entry.value, entry.key));
    }
    return tiles;
  }
}
