enum MoveQuality {
  best,
  excellent,
  good,
  inaccuracy,
  mistake,
  blunder,
}

class MoveQualityClassifier {
  const MoveQualityClassifier({
    this.excellentLoss = 5,
    this.goodLoss = 12,
    this.inaccuracyLoss = 25,
    this.mistakeLoss = 45,
  });

  final int excellentLoss;
  final int goodLoss;
  final int inaccuracyLoss;
  final int mistakeLoss;

  MoveQuality classify({
    required int bestScore,
    required int playedScore,
  }) {
    final loss = bestScore - playedScore;
    if (loss <= 0) return MoveQuality.best;
    if (loss <= excellentLoss) return MoveQuality.excellent;
    if (loss <= goodLoss) return MoveQuality.good;
    if (loss <= inaccuracyLoss) return MoveQuality.inaccuracy;
    if (loss <= mistakeLoss) return MoveQuality.mistake;
    return MoveQuality.blunder;
  }
}
