import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_progression.dart';

void main() {
  test('rank rises gradually and ends at Usta Kelimebaz', () {
    expect(PlayerProgression.fromXp(0).title, 'Acemi Kelimebaz');
    expect(PlayerProgression.fromXp(1700).title, 'Amatör Kelimebaz');
    expect(PlayerProgression.fromXp(9000).title, 'Usta Kelimebaz');
  });

  test('match experience uses score and capped play duration', () {
    expect(
      PlayerProgression.experienceForMatch(
        score: 80,
        duration: const Duration(minutes: 15),
      ),
      110,
    );
    expect(
      PlayerProgression.experienceForMatch(
        score: 80,
        duration: const Duration(hours: 4),
      ),
      320,
    );
  });
}
