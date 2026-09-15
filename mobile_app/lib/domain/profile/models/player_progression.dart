import 'dart:math' as math;

enum WordsmithRank {
  novice(title: 'Acemi Kelimebaz', minimumXp: 0),
  apprentice(title: 'Çırak Kelimebaz', minimumXp: 600),
  amateur(title: 'Amatör Kelimebaz', minimumXp: 1600),
  experienced(title: 'Deneyimli Kelimebaz', minimumXp: 3200),
  expert(title: 'Uzman Kelimebaz', minimumXp: 5600),
  master(title: 'Usta Kelimebaz', minimumXp: 9000);

  const WordsmithRank({required this.title, required this.minimumXp});

  final String title;
  final int minimumXp;
}

class PlayerProgression {
  const PlayerProgression({required this.xp, required this.rank});

  factory PlayerProgression.fromXp(int value) {
    final xp = math.max(0, value);
    var rank = WordsmithRank.novice;
    for (final candidate in WordsmithRank.values) {
      if (xp >= candidate.minimumXp) rank = candidate;
    }
    return PlayerProgression(xp: xp, rank: rank);
  }

  final int xp;
  final WordsmithRank rank;

  int get level => 1 + (xp ~/ 500);
  String get title => rank.title;

  WordsmithRank? get nextRank {
    final index = WordsmithRank.values.indexOf(rank);
    return index == WordsmithRank.values.length - 1
        ? null
        : WordsmithRank.values[index + 1];
  }

  double get rankProgress {
    final next = nextRank;
    if (next == null) return 1;
    final range = next.minimumXp - rank.minimumXp;
    return ((xp - rank.minimumXp) / range).clamp(0, 1);
  }

  int get xpToNextRank => math.max(0, (nextRank?.minimumXp ?? xp) - xp);

  static int experienceForMatch({
    required int score,
    required Duration duration,
  }) {
    final scoreXp = math.max(0, score);
    final playedMinutes = math.max(1, duration.inMinutes);
    final durationXp = math.min(playedMinutes, 120) * 2;
    return scoreXp + durationXp;
  }
}
