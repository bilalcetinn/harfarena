import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:kelime_analiz_mobile/ui/games/games_view.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_tabs.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/my_games_list.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';

OnlineRoom _room(
  String code, {
  String status = 'playing',
  String turnUid = 'me',
  String? guestUid = 'rival',
  String? invitedGuestUid,
  String? invitedGuestName,
  int duration = 86400,
}) => OnlineRoom(
  code: code,
  hostUid: 'me',
  guestUid: guestUid,
  turnUid: turnUid,
  status: status,
  seed: 42,
  turnStartedAt: DateTime(2026, 9, 8),
  hostName: 'Bilal',
  guestName: guestUid == null ? null : 'Rakip_$code',
  invitedGuestUid: invitedGuestUid,
  invitedGuestName: invitedGuestName,
  turnDurationSeconds: duration,
);

GamesView _gamesView({
  required Stream<List<OnlineRoom>> rooms,
  Stream<List<MatchHistoryEntry>>? history,
  ValueChanged<OnlineRoom>? onOpen,
  ValueChanged<MatchHistoryEntry>? onAnalyze,
  VoidCallback? onNewGame,
}) => GamesView(
  roomsStream: rooms,
  historyStream: history ?? Stream.value(const []),
  movesForRoom: (_) => Stream.value(const <OnlineMove>[]),
  currentPlayerId: 'me',
  currentUsername: 'Bilal',
  onAcceptInvite: (_) async {},
  onRejectInvite: (_) async {},
  onCancelInvite: (_) async {},
  onOpenGame: onOpen ?? (_) {},
  onAnalyze: onAnalyze ?? (_) {},
  onNewGame: onNewGame ?? () {},
  onNavigationSelected: (_) {},
);

void main() {
  testWidgets('birden fazla macin sirasi ve suresi bagimsiz gosterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MyGamesList(
                currentPlayerId: 'me',
                onOpen: (room) => opened.add(room.code),
                rooms: [
                  _room('AAAA2222', duration: 300),
                  _room('BBBB2222', turnUid: 'rival', duration: 0),
                  _room(
                    'CCCC2222',
                    status: 'waiting',
                    guestUid: null,
                    invitedGuestUid: 'friend',
                    invitedGuestName: 'UzunKullaniciAdi',
                  ),
                  _room('DDDD2222', status: 'finished'),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('3 maç'), findsOneWidget);
    expect(find.text('Sıra sende'), findsOneWidget);
    expect(find.text('Rakibin sırası'), findsOneWidget);
    expect(find.text('Davet gönderildi'), findsOneWidget);
    expect(find.text('5 dakika / hamle'), findsOneWidget);
    expect(find.text('Süresiz / hamle'), findsOneWidget);
    expect(find.textContaining('DDDD2222'), findsNothing);

    await tester.tap(find.text('Rakip_BBBB2222'));
    await tester.tap(find.text('Rakip_AAAA2222'));
    expect(opened, ['BBBB2222', 'AAAA2222']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oyunlarim canli guncellenir ve yeni mac aksiyonu calisir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rooms = StreamController<List<OnlineRoom>>();
    addTearDown(rooms.close);
    var newGameCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: _gamesView(rooms: rooms.stream, onNewGame: () => newGameCount++),
      ),
    );
    rooms.add([_room('AAAA2222')]);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(GamesTabs), matching: find.text('1')),
      findsOneWidget,
    );

    rooms.add([_room('AAAA2222'), _room('BBBB2222')]);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(GamesTabs), matching: find.text('2')),
      findsOneWidget,
    );

    await tester.tap(find.text('YENİ OYUN'));
    expect(newGameCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gecmisteki mac sonucu callback ile acilir', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const match = MatchHistoryEntry(
      roomCode: 'DONE2222',
      hostName: 'Bilal',
      guestName: 'Rakip',
      hostScore: 117,
      guestScore: 152,
      sequence: 1,
    );
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: _gamesView(
          rooms: Stream.value(const []),
          history: Stream.value(const [match]),
          onAnalyze: (entry) => opened.add(entry.roomCode),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bitenler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sonucu Gör'));

    expect(opened, ['DONE2222']);
    expect(tester.takeException(), isNull);
  });
}
