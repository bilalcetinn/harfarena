import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';

void main() {
  test('recorded winner overrides scores for a forfeited match', () {
    const match = MatchHistoryEntry(
      roomCode: 'ABCDEFGH',
      hostName: 'bilalcetin',
      guestName: 'bilal',
      hostScore: 0,
      guestScore: 14,
      sequence: 1,
      winnerUid: 'host-id',
    );

    expect(
      match.outcomeFor(playerId: 'host-id', username: 'bilalcetin'),
      MatchOutcome.win,
    );
    expect(
      match.outcomeFor(playerId: 'guest-id', username: 'bilal'),
      MatchOutcome.loss,
    );
  });

  test('legacy history without a winner still uses the scores', () {
    const match = MatchHistoryEntry(
      roomCode: 'ABCDEFGH',
      hostName: 'host',
      guestName: 'guest',
      hostScore: 8,
      guestScore: 8,
      sequence: 1,
    );

    expect(
      match.outcomeFor(playerId: 'host-id', username: 'host'),
      MatchOutcome.draw,
    );
  });
}
