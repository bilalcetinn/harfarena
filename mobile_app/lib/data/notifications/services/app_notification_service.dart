import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:kelime_analiz_mobile/domain/notifications/repositories/app_notification_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/local_settings.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/local_settings_repository.dart';

class AppNotificationService implements AppNotificationRepository {
  AppNotificationService(
    this._settings, {
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'harf_arena_game_events_v1';
  static const quietChannelId = 'harf_arena_game_events_quiet_v1';
  static const _channelName = 'Oyun bildirimleri';
  static const _channelDescription =
      'Sıra, davet, yeni oyun ve maç sonucu bildirimleri';
  static const _notificationSound = RawResourceAndroidNotificationSound('turn');

  final LocalSettingsRepository _settings;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  final StreamController<String> _openedRoomCodes =
      StreamController<String>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _playerId;
  String? _storedToken;
  String? _pendingRoomCode;
  Future<void>? _initialization;
  bool _initialized = false;
  int _registrationEpoch = 0;

  @override
  Stream<String> get openedRoomCodes => _openedRoomCodes.stream;

  @override
  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    final pending = _initialization;
    if (pending != null) return pending;

    final initialization = _initialize();
    _initialization = initialization;
    return initialization.then(
      (_) {
        _initialized = true;
      },
      onError: (Object error, StackTrace stackTrace) {
        _initialization = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<void> _initialize() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        _emitRoomCode(response.payload);
      },
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        sound: _notificationSound,
        enableVibration: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        quietChannelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        sound: _notificationSound,
        enableVibration: false,
      ),
    );

    final localLaunch = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (localLaunch?.didNotificationLaunchApp ?? false) {
      _pendingRoomCode = localLaunch?.notificationResponse?.payload;
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingRoomCode = initialMessage.data['roomCode'];
    }

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
  }

  @override
  Future<bool> registerForPlayer(
    String playerId, {
    bool requestPermission = true,
  }) async {
    final epoch = ++_registrationEpoch;
    _playerId = playerId;

    try {
      await initialize();
      if (!_isCurrentRegistration(playerId, epoch)) return false;
      _flushPendingRoomCode();

      if (requestPermission) {
        final permission = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (!_isCurrentRegistration(playerId, epoch) ||
            !_isAuthorized(permission.authorizationStatus)) {
          return false;
        }
      }

      final token = await _messaging.getToken();
      if (!_isCurrentRegistration(playerId, epoch)) return false;
      if (token != null && token.isNotEmpty) {
        await _storeToken(token, playerId: playerId, epoch: epoch);
      }
      _tokenSubscription ??= _messaging.onTokenRefresh.listen(
        (token) => unawaited(_storeRefreshedToken(token)),
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('FCM token yenilenemedi: $error');
        },
      );
      return true;
    } catch (error) {
      debugPrint('Bildirim cihaz kaydı yapılamadı: $error');
      return false;
    }
  }

  static bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  bool _isCurrentRegistration(String playerId, int epoch) =>
      _playerId == playerId && _registrationEpoch == epoch;

  Future<void> _storeRefreshedToken(String token) async {
    final playerId = _playerId;
    final epoch = _registrationEpoch;
    if (playerId == null || playerId.isEmpty) return;

    try {
      await _storeToken(token, playerId: playerId, epoch: epoch);
    } catch (error) {
      debugPrint('FCM token yenilenemedi: $error');
    }
  }

  Future<void> _storeToken(
    String token, {
    required String playerId,
    required int epoch,
  }) async {
    if (token.isEmpty || !_isCurrentRegistration(playerId, epoch)) return;

    final previousToken = _storedToken;
    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    final deviceRef = _firestore
        .collection('players')
        .doc(playerId)
        .collection('devices')
        .doc(tokenId);
    await deviceRef.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!_isCurrentRegistration(playerId, epoch)) {
      try {
        await deviceRef.delete();
      } catch (error) {
        debugPrint('Eski bildirim cihaz kaydı silinemedi: $error');
      }
      return;
    }
    _storedToken = token;

    if (previousToken != null && previousToken != token) {
      try {
        await _deviceRef(playerId, previousToken).delete();
      } catch (error) {
        debugPrint('Eski FCM token kaydı silinemedi: $error');
      }
    }
  }

  DocumentReference<Map<String, dynamic>> _deviceRef(
    String playerId,
    String token,
  ) {
    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    return _firestore
        .collection('players')
        .doc(playerId)
        .collection('devices')
        .doc(tokenId);
  }

  @override
  Future<void> unregisterCurrentDevice() async {
    final playerId = _playerId;
    final tokens = <String>{?_storedToken};
    _registrationEpoch++;
    _playerId = null;
    _storedToken = null;

    try {
      final currentToken = await _messaging.getToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        tokens.add(currentToken);
      }
    } catch (error) {
      debugPrint('FCM token okunamadı: $error');
    }

    if (playerId == null || tokens.isEmpty) return;

    for (final token in tokens) {
      try {
        await _deviceRef(playerId, token).delete();
      } catch (error) {
        debugPrint('Bildirim cihaz kaydı silinemedi: $error');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final settings = await _settings.load();
    if (!_isEnabled(message.data['type'], settings)) return;

    final title =
        message.notification?.title ?? message.data['title'] ?? 'HarfArena';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final vibrate = settings.vibrationEnabled;

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      title: title,
      body: body,
      payload: message.data['roomCode'],
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          vibrate ? channelId : quietChannelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          sound: _notificationSound,
          enableVibration: vibrate,
        ),
      ),
    );
  }

  static bool _isEnabled(String? type, LocalSettings settings) =>
      switch (type) {
        'turn' => settings.turnNotificationsEnabled,
        'invite' || 'game_opened' => settings.inviteNotificationsEnabled,
        'result' => settings.resultNotificationsEnabled,
        _ => true,
      };

  void _handleOpenedMessage(RemoteMessage message) {
    _emitRoomCode(message.data['roomCode']);
  }

  void _emitRoomCode(String? rawCode) {
    final code = rawCode?.trim().toUpperCase();
    if (code == null || code.length != 8) return;
    if (_playerId == null) {
      _pendingRoomCode = code;
      return;
    }
    _openedRoomCodes.add(code);
  }

  void _flushPendingRoomCode() {
    final code = _pendingRoomCode;
    _pendingRoomCode = null;
    _emitRoomCode(code);
  }

  @override
  Future<void> dispose() async {
    await Future.wait<void>([
      if (_foregroundSubscription != null) _foregroundSubscription!.cancel(),
      if (_openedSubscription != null) _openedSubscription!.cancel(),
      if (_tokenSubscription != null) _tokenSubscription!.cancel(),
    ]);
    await _openedRoomCodes.close();
  }
}
