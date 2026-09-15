import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/di/app_providers.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';
import 'package:kelime_analiz_mobile/domain/notifications/repositories/app_notification_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_repository.dart';
import 'package:kelime_analiz_mobile/ui/app/app_bootstrap.dart';

void main() {
  testWidgets('signed-out startup initializes repositories and opens login', (
    tester,
  ) async {
    final accounts = _SignedOutAccounts();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(accounts),
          playerProfileRepositoryProvider.overrideWithValue(_Profiles()),
          appNotificationRepositoryProvider.overrideWithValue(_Notifications()),
        ],
        child: const MaterialApp(home: AppBootstrap()),
      ),
    );

    await tester.pump();

    expect(accounts.loadCurrentProfileCalled, isTrue);
    expect(find.textContaining('LateInitializationError'), findsNothing);
  });
}

class _SignedOutAccounts implements AccountRepository {
  bool loadCurrentProfileCalled = false;

  @override
  bool get currentUserNeedsEmailVerification => false;

  @override
  String? get currentUserEmail => null;

  @override
  Future<PlayerProfile?> loadCurrentProfile() async {
    loadCurrentProfileCalled = true;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements PlayerProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications implements AppNotificationRepository {
  @override
  Stream<String> get openedRoomCodes => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> registerForPlayer(
    String playerId, {
    bool requestPermission = true,
  }) async => true;

  @override
  Future<void> unregisterCurrentDevice() async {}
}
