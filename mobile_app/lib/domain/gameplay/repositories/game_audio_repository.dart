enum GameSound {
  uiTap,
  tilePick,
  tileDrop,
  moveSuccess,
  moveError,
  turn,
  invite,
  win,
  lose,
}

abstract interface class GameAudioRepository {
  Future<void> play(GameSound sound);
  Future<void> setEnabled(bool value);
  Future<void> dispose();
}
