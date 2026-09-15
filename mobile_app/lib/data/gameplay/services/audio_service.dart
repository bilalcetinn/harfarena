import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:kelime_analiz_mobile/core/constants/app_assets.dart';
import 'package:kelime_analiz_mobile/data/profile/services/local_settings_service.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/game_audio_repository.dart';

/// Merkezi oyun ses servisi.
///
/// Taş / UI efektleri ile sıra-davet-sonuç sesleri ayrı player kullanır.
/// Böylece örneğin taş bırakma sesi, aynı anda gelen "sıra sende" sesini
/// yarıda kesmez.
class AudioService implements GameAudioRepository {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _notificationPlayer = AudioPlayer();
  final LocalSettingsService _settings = LocalSettingsService();

  bool? _enabled;

  @override
  Future<void> play(GameSound sound) async {
    if (!await _isEnabled()) return;

    final player = _isNotification(sound) ? _notificationPlayer : _effectPlayer;

    try {
      // Aynı kanalda çok hızlı art arda gelen eski sesi kesip
      // yeni aksiyonun sesini çal. Diğer kanal etkilenmez.
      await player.stop();
      await player.play(AssetSource(_assetPath(sound)), volume: _volume(sound));
    } catch (error, stackTrace) {
      // Ses hiçbir zaman oyunu bozmasın; debug çalıştırmada ise gerçek
      // asset/codec hatasını görünür bırak.
      debugPrint('Game sound could not be played (${sound.name}): $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;

    if (!value) {
      await Future.wait([_effectPlayer.stop(), _notificationPlayer.stop()]);
    }

    await _settings.setSoundEnabled(value);
  }

  Future<bool> _isEnabled() async {
    final cached = _enabled;
    if (cached != null) return cached;

    _enabled = (await _settings.load()).soundEnabled;
    return _enabled!;
  }

  static bool _isNotification(GameSound sound) => switch (sound) {
    GameSound.turn ||
    GameSound.invite ||
    GameSound.win ||
    GameSound.lose => true,
    _ => false,
  };

  static double _volume(GameSound sound) => switch (sound) {
    GameSound.uiTap => 0.35,
    GameSound.tilePick => 0.50,
    GameSound.tileDrop => 0.62,
    GameSound.moveSuccess => 0.78,
    GameSound.moveError => 0.68,
    GameSound.turn => 0.82,
    GameSound.invite => 0.82,
    GameSound.win => 0.90,
    GameSound.lose => 0.82,
  };

  static String _assetPath(GameSound sound) => switch (sound) {
    GameSound.uiTap => AppAssets.uiTapSound,
    GameSound.tilePick => AppAssets.tilePickSound,
    GameSound.tileDrop => AppAssets.tileDropSound,
    GameSound.moveSuccess => AppAssets.moveSuccessSound,
    GameSound.moveError => AppAssets.moveErrorSound,
    GameSound.turn => AppAssets.turnSound,
    GameSound.invite => AppAssets.inviteSound,
    GameSound.win => AppAssets.winSound,
    GameSound.lose => AppAssets.loseSound,
  };

  @override
  Future<void> dispose() async {
    await Future.wait([_effectPlayer.dispose(), _notificationPlayer.dispose()]);
  }
}
