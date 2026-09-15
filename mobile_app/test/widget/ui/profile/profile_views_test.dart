import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_details_repository.dart';
import 'package:kelime_analiz_mobile/ui/profile/edit_profile_view.dart';
import 'package:kelime_analiz_mobile/ui/profile/profile_view.dart';

void main() {
  testWidgets(
    'profile uses display name and exposes edit action without pull refresh',
    (tester) async {
      var editPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileView(
            username: 'bilalcetin',
            displayName: 'Bilal Çetin',
            avatarUrl: null,
            playerId: 'p1',
            historyStream: Stream<List<MatchHistoryEntry>>.value(const []),
            onNavigationSelected: (_) {},
            onEditProfile: () => editPressed = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bilal Çetin'), findsOneWidget);
      expect(find.text('@bilalcetin'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsNothing);

      await tester.tap(find.byKey(const Key('profile_edit_button')));
      expect(editPressed, isTrue);
    },
  );

  testWidgets('edit profile has the shared section header and no about field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditProfileView(
          playerId: 'p1',
          username: 'bilalcetin',
          initialAvatarUrl: null,
          accounts: _Accounts(),
          profiles: _Profiles(),
        ),
      ),
    );

    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(find.text('KULLANICI ADI'), findsOneWidget);
    expect(find.textContaining('Hakkımda'), findsNothing);
    expect(find.textContaining('HAKKIMDA'), findsNothing);
    expect(find.text('DEĞİŞİKLİKLERİ KAYDET'), findsOneWidget);
  });
}

class _Accounts implements AccountRepository {
  @override
  bool get currentUserCanChangePassword => false;

  @override
  bool get currentUserNeedsEmailVerification => false;

  @override
  String? get currentUserEmail => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements PlayerProfileDetailsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
