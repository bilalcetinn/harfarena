import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kelime_analiz_mobile/data/account/services/account_service.dart';
import 'package:kelime_analiz_mobile/data/notifications/services/app_notification_service.dart';
import 'package:kelime_analiz_mobile/data/analysis/services/word_definition_service.dart';
import 'package:kelime_analiz_mobile/data/gameplay/services/audio_service.dart';
import 'package:kelime_analiz_mobile/data/gameplay/services/online_game_service.dart';
import 'package:kelime_analiz_mobile/data/games/services/game_invite_actions_service.dart';
import 'package:kelime_analiz_mobile/data/profile/services/local_settings_service.dart';
import 'package:kelime_analiz_mobile/data/profile/services/player_backend_service.dart';
import 'package:kelime_analiz_mobile/data/profile/services/player_profile_service.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';
import 'package:kelime_analiz_mobile/domain/analysis/repositories/word_definition_repository.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/game_audio_repository.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/online_game_repository.dart';
import 'package:kelime_analiz_mobile/domain/games/repositories/game_invite_actions_repository.dart';
import 'package:kelime_analiz_mobile/domain/notifications/repositories/app_notification_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/local_settings_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_details_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountService(),
);

final playerProfileRepositoryProvider = Provider<PlayerProfileRepository>(
  (ref) => PlayerProfileService(),
);

final playerProfileDetailsRepositoryProvider =
    Provider<PlayerProfileDetailsRepository>((ref) => PlayerBackendService());

final localSettingsRepositoryProvider = Provider<LocalSettingsRepository>(
  (ref) => LocalSettingsService(),
);

final appNotificationRepositoryProvider = Provider<AppNotificationRepository>((
  ref,
) {
  final notifications = AppNotificationService(
    ref.read(localSettingsRepositoryProvider),
  );
  ref.onDispose(() => unawaited(notifications.dispose()));
  return notifications;
});

final wordDefinitionRepositoryProvider = Provider<WordDefinitionRepository>(
  (ref) => WordDefinitionService(),
);

final gameAudioRepositoryProvider = Provider<GameAudioRepository>((ref) {
  final audio = AudioService.instance;
  ref.onDispose(audio.dispose);
  return audio;
});

final onlineGameRepositoryProvider =
    Provider.family<OnlineGameRepository, PlayerProfile>(
      (ref, profile) =>
          OnlineGameService(playerId: profile.id, playerName: profile.username),
    );

final gameInviteActionsRepositoryProvider =
    Provider.family<GameInviteActionsRepository, String>(
      (ref, playerId) => GameInviteActionsService(playerId: playerId),
    );
