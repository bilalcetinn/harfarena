import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kelime_analiz_mobile/core/constants/app_assets.dart';
import 'package:kelime_analiz_mobile/di/app_providers.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/online_game_repository.dart';
import 'package:kelime_analiz_mobile/domain/games/repositories/game_invite_actions_repository.dart';
import 'package:kelime_analiz_mobile/domain/notifications/repositories/app_notification_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_details_repository.dart';
import 'package:flutter/services.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/account/email_verification_view.dart';
import 'package:kelime_analiz_mobile/ui/account/login_view.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:kelime_analiz_mobile/ui/app/game_event_monitor.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/online_lobby_view.dart';
import 'package:kelime_analiz_mobile/ui/games/games_view.dart';
import 'package:kelime_analiz_mobile/ui/games/new_game_view.dart';
import 'package:kelime_analiz_mobile/ui/home/home_view.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_backend_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_stats.dart';
import 'package:kelime_analiz_mobile/ui/profile/profile_view.dart';
import 'package:kelime_analiz_mobile/ui/profile/edit_profile_view.dart';
import 'package:kelime_analiz_mobile/ui/profile/settings_view.dart';
import 'package:kelime_analiz_mobile/ui/splash/splash_view.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/arena_glass_background.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/app_page_route.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_bottom_navigation.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

Future<TrieWordDictionary> _buildDictionary(String source) {
  return Isolate.run(() => TrieWordDictionary(source.split(RegExp(r'\r?\n'))));
}

/// Tek Firestore aboneliğini paylaşır ve her yeni dinleyiciye son değeri verir.
/// IndexedStack içindeki ekranlar farklı anlarda dinlemeye başlasa da ilk oda
/// veya geçmiş snapshot'ını kaçırmaz.
Stream<T> _shareLatest<T>(Stream<T> source, T initialValue) {
  var latest = initialValue;
  final shared = source.map((value) {
    latest = value;
    return value;
  }).asBroadcastStream();

  return Stream<T>.multi((controller) {
    controller.addSync(latest);
    final subscription = shared.listen(
      controller.addSync,
      onError: controller.addErrorSync,
      onDone: controller.closeSync,
    );
    controller
      ..onPause = subscription.pause
      ..onResume = subscription.resume
      ..onCancel = subscription.cancel;
  }, isBroadcast: true);
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  late final AccountRepository _accounts;
  late final PlayerProfileRepository _profiles;
  late final AppNotificationRepository _notifications;
  PlayerProfileDetailsRepository? _profileDetails;

  TrieWordDictionary? _dictionary;
  PlayerProfile? _profile;
  OnlineGameRepository? _games;
  GameInviteActionsRepository? _inviteActions;
  Stream<List<OnlineRoom>>? _roomsStream;
  Stream<List<MatchHistoryEntry>>? _historyStream;
  Stream<PlayerBackendProfile?>? _profileDetailsStream;
  GameEventMonitor? _gameEventMonitor;
  StreamSubscription<String>? _notificationOpenSubscription;
  String? _pendingNotificationRoomCode;
  Object? _error;
  bool _loading = true;
  int _selectedNavigationIndex = 0;
  final ValueNotifier<bool> _subrouteOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _accounts = ref.read(accountRepositoryProvider);
    _profiles = ref.read(playerProfileRepositoryProvider);
    _notifications = ref.read(appNotificationRepositoryProvider);
    unawaited(_initializeNotifications());
    _notificationOpenSubscription = _notifications.openedRoomCodes.listen(
      _handleNotificationRoom,
    );
    _load();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notifications.initialize();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app notifications',
          context: ErrorDescription('while initializing notifications'),
        ),
      );
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object?>([
        rootBundle
            .loadString(AppAssets.words)
            .then<TrieWordDictionary>(_buildDictionary),
        _accounts.loadCurrentProfile(),
      ]);
      if (!mounted) return;

      final profile = results[1] as PlayerProfile?;
      setState(() {
        _dictionary = results[0] as TrieWordDictionary;
        if (profile != null) _configureSession(profile);
        _loading = false;
      });
      FlutterNativeSplash.remove();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
      FlutterNativeSplash.remove();
    }
  }

  void _configureSession(PlayerProfile profile) {
    unawaited(_gameEventMonitor?.dispose());
    final games = ref.read(onlineGameRepositoryProvider(profile));
    final profileDetails = ref.read(playerProfileDetailsRepositoryProvider);
    _profile = profile;
    _games = games;
    _profileDetails = profileDetails;
    _inviteActions = ref.read(gameInviteActionsRepositoryProvider(profile.id));
    _roomsStream = _shareLatest<List<OnlineRoom>>(
      games.myRooms(),
      const <OnlineRoom>[],
    );
    _historyStream = _shareLatest<List<MatchHistoryEntry>>(
      _profiles.history(profile.username),
      const <MatchHistoryEntry>[],
    );
    unawaited(profileDetails.ensureProfile(profile));
    _profileDetailsStream = _shareLatest<PlayerBackendProfile?>(
      profileDetails.profile(profile.id),
      null,
    );
    _gameEventMonitor = GameEventMonitor(
      games: games,
      roomsStream: _roomsStream!,
      currentPlayerId: profile.id,
      onEvent: _showGameEvent,
    )..start();
    unawaited(_notifications.registerForPlayer(profile.id));
    _selectedNavigationIndex = 0;
    _drainPendingNotification();
  }

  void _showGameEvent(AppGameEvent event) {
    unawaited(_showEnabledGameEvent(event));
  }

  Future<void> _showEnabledGameEvent(AppGameEvent event) async {
    final settings = await ref.read(localSettingsRepositoryProvider).load();
    final enabled = switch (event) {
      OpponentMoveAppGameEvent() => settings.turnNotificationsEnabled,
      GameOpenedAppGameEvent() => settings.inviteNotificationsEnabled,
    };
    if (!enabled) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      final (icon, message) = switch (event) {
        OpponentMoveAppGameEvent(
          :final opponentName,
          :final word,
          :final score,
        ) =>
          (
            Icons.sports_esports_rounded,
            '$opponentName hamle yaptı (${word.toUpperCase()}) $score puan',
          ),
        GameOpenedAppGameEvent(:final opponentName) => (
          Icons.handshake_rounded,
          '$opponentName ile oyun açıldı',
        ),
      };

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF123D29),
            content: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDEF5E6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.brandGreen, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    });
  }

  void _completeAuthentication(PlayerProfile profile) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _configureSession(profile));
  }

  Future<String?> _findFriend(String username) async {
    return (await _profiles.findByUsername(username))?.username;
  }

  Future<void> _createFriendGame(String username, int turnDurationSeconds) {
    return _games!.createRoom(
      targetUsername: username,
      turnDurationSeconds: turnDurationSeconds,
    );
  }

  Future<T?> _pushPage<T>(BuildContext context, WidgetBuilder builder) async {
    if (!mounted) return null;
    _subrouteOpen.value = true;

    try {
      return await Navigator.of(context)
          .push<T>(AppPageRoute<T>(builder: builder));
    } finally {
      if (mounted) {
        _subrouteOpen.value = false;
        _drainPendingNotification();
      }
    }
  }

  Future<void> _openNewGame(BuildContext context) async {
    final settings = await ref.read(localSettingsRepositoryProvider).load();
    if (!context.mounted) return;
    await _pushPage<void>(
      context,
      (newGameContext) => NewGameView(
        currentUsername: _profile!.username,
        initialTurnDurationSeconds: settings.defaultTurnDurationSeconds,
        onFindFriend: _findFriend,
        onCreateFriendGame: _createFriendGame,
        onRandomContinue: () {
          ScaffoldMessenger.of(newGameContext).showSnackBar(
            const SnackBar(
              content: Text('Rastgele eşleşme yakında kullanıma açılacak.'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRoom(BuildContext context, String roomCode) async {
    await _pushPage<void>(
      context,
      (_) => OnlineLobbyScreen(
        dictionary: _dictionary!,
        profile: _profile!,
        profileService: _profiles,
        initialRoomCode: roomCode,
        gameService: _games!,
        audio: ref.read(gameAudioRepositoryProvider),
        definitions: ref.read(wordDefinitionRepositoryProvider),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await _pushPage<void>(
      context,
      (_) => SettingsView(
        onLogout: () => _logout(context),
        playerId: _profile!.id,
        preferencesService: ref.read(localSettingsRepositoryProvider),
        profiles: _profileDetails!,
        notifications: _notifications,
        audio: ref.read(gameAudioRepositoryProvider),
      ),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    PlayerBackendProfile? details,
  ) async {
    final profile = _profile!;
    final result = await _pushPage<EditProfileResult>(
      context,
      (_) => EditProfileView(
        playerId: profile.id,
        username: profile.username,
        initialAvatarUrl: details?.avatarUrl,
        accounts: _accounts,
        profiles: _profileDetails!,
      ),
    );
    if (result != null && context.mounted) {
      if (result.usernameChanged && mounted) {
        setState(() {
          _configureSession(result.profile);
          // Profili düzenledikten sonra kullanıcıyı Ana Sayfa'ya atma.
          _selectedNavigationIndex = 3;
        });
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profilin güncellendi.')));
    }
  }

  Future<void> _logout(BuildContext routeContext) async {
    final gameEventMonitor = _gameEventMonitor;
    _gameEventMonitor = null;
    await gameEventMonitor?.dispose();
    try {
      await _notifications.unregisterCurrentDevice();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app notifications',
          context: ErrorDescription(
            'while unregistering the current notification device',
          ),
        ),
      );
    }
    await Future.wait<void>([_accounts.signOut(), _profiles.logout()]);
    if (!mounted) return;

    if (routeContext.mounted) {
      Navigator.of(routeContext).popUntil((route) => route.isFirst);
    }
    setState(() {
      _profile = null;
      _games = null;
      _profileDetails = null;
      _inviteActions = null;
      _roomsStream = null;
      _historyStream = null;
      _profileDetailsStream = null;
      _selectedNavigationIndex = 0;
    });
  }

  void _selectNavigation(int index) {
    if (index == _selectedNavigationIndex) return;
    setState(() => _selectedNavigationIndex = index);
  }

  void _handleNotificationRoom(String roomCode) {
    _pendingNotificationRoomCode = roomCode;
    _drainPendingNotification();
  }

  void _drainPendingNotification() {
    if (!mounted ||
        _profile == null ||
        _games == null ||
        _dictionary == null ||
        _subrouteOpen.value) {
      return;
    }
    final roomCode = _pendingNotificationRoomCode;
    if (roomCode == null) return;
    _pendingNotificationRoomCode = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openRoom(context, roomCode));
    });
  }

  Widget _keepAliveTab(int index, Widget child) {
    return ValueListenableBuilder<bool>(
      valueListenable: _subrouteOpen,
      child: RepaintBoundary(child: child),
      builder: (context, subrouteOpen, child) => TickerMode(
        enabled: !subrouteOpen && _selectedNavigationIndex == index,
        child: child!,
      ),
    );
  }

  Widget _buildMainShell(BuildContext context) {
    final profile = _profile!;
    final games = _games!;

    final pages = <Widget>[
      StreamBuilder<PlayerBackendProfile?>(
        stream: _profileDetailsStream,
        builder: (context, snapshot) => HomeView(
          username: profile.username,
          playerStats: snapshot.data?.stats ?? const PlayerStats(),
          onPlay: () => _openNewGame(context),
          onSettings: () => _openSettings(context),
          onNavigationSelected: _selectNavigation,
          showBottomNavigation: false,
        ),
      ),
      GamesView(
        roomsStream: _roomsStream!,
        historyStream: _historyStream!,
        movesForRoom: games.moves,
        currentPlayerId: profile.id,
        currentUsername: profile.username,
        onAcceptInvite: (room) async {
          final joined = await games.joinRoom(room.code);
          if (context.mounted) _openRoom(context, joined.code);
        },
        onRejectInvite: _inviteActions!.cancelOrRejectInvite,
        onCancelInvite: _inviteActions!.cancelOrRejectInvite,
        onOpenGame: (room) => _openRoom(context, room.code),
        onAnalyze: (match) => _openRoom(context, match.roomCode),
        onNewGame: () => _openNewGame(context),
        onNavigationSelected: _selectNavigation,
        showBottomNavigation: false,
      ),
      const _LeaderboardPlaceholder(),
      StreamBuilder<PlayerBackendProfile?>(
        stream: _profileDetailsStream,
        builder: (context, snapshot) {
          final details = snapshot.data;
          return ProfileView(
            playerId: profile.id,
            username: profile.username,
            displayName: details?.visibleName ?? profile.username,
            avatarUrl: details?.avatarUrl,
            playerStats: details?.stats ?? const PlayerStats(),
            historyStream: _historyStream!,
            onNavigationSelected: _selectNavigation,
            onEditProfile: () => _openEditProfile(context, details),
            onOpenMatch: (match) => _openRoom(context, match.roomCode),
            showBottomNavigation: false,
          );
        },
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.brandGreenDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Oyunlarım / Liderlik / Profil için tek ve kalıcı arka plan.
            // Home kendi opak arka planını çizdiği için burada görünmez;
            // fakat bu widget shell boyunca mount'ta kalır ve animasyon
            // sekme değiştirirken sıfırlanmaz.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _subrouteOpen,
                child: Offstage(
                  offstage: _selectedNavigationIndex == 0,
                  child: const RepaintBoundary(child: ArenaGlassBackground()),
                ),
                builder: (context, subrouteOpen, child) => TickerMode(
                  enabled: !subrouteOpen && _selectedNavigationIndex != 0,
                  child: child!,
                ),
              ),
            ),
            Positioned.fill(
              child: IndexedStack(
                index: _selectedNavigationIndex,
                children: [
                  for (var index = 0; index < pages.length; index++)
                    _keepAliveTab(index, pages[index]),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigation(
          selectedIndex: _selectedNavigationIndex,
          onDestinationSelected: _selectNavigation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashView();
    if (_error != null || _dictionary == null) {
      return _BootstrapErrorView(error: _error, onRetry: _retry);
    }
    if (_profile == null) {
      if (_accounts.currentUserNeedsEmailVerification) {
        return EmailVerificationView(
          service: _accounts,
          onVerified: _completeAuthentication,
          onSignedOut: () {
            if (mounted) {
              setState(() {});
            }
          },
        );
      }

      return LoginView(service: _accounts, onReady: _completeAuthentication);
    }
    return _buildMainShell(context);
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  @override
  void dispose() {
    unawaited(_gameEventMonitor?.dispose());
    unawaited(_notificationOpenSubscription?.cancel());
    _subrouteOpen.dispose();
    super.dispose();
  }
}

class _LeaderboardPlaceholder extends StatelessWidget {
  const _LeaderboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          MainSectionHeader(
            title: 'Liderlik',
            subtitle:
                'Sıralamadaki yerini gör, zirve için kelimelerinle yarış.',
            icon: Icons.emoji_events_rounded,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: FrostedGlassPanel(
                  padding: EdgeInsets.fromLTRB(28, 28, 28, 26),
                  borderRadius: 24,
                  backgroundOpacity: 0.76,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 58,
                        color: AppColors.brandGreen,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Liderlik tablosu yakında',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Oyuncular çoğaldıkça haftalık sıralama burada görünecek.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF707873)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Uygulama başlatılamadı.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
