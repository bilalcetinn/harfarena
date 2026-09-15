import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/ui/games/new_game_view.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      home: NewGameView(
        currentUsername: 'ahmet',

        onFindFriend: (username) async {
          if (username.toLowerCase() == 'can35') {
            return 'can35';
          }

          return null;
        },

        onCreateFriendGame: (username, duration) async {},

        onRandomContinue: () {},
      ),
    );
  }

  testWidgets('Yeni oyun ekranı açılır', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Rakibini Seç'), findsOneWidget);

    expect(find.text('Arkadaşınla Oyna'), findsOneWidget);

    expect(find.text('Rastgele Rakip'), findsOneWidget);

    expect(find.text('Hamle Süresi'), findsOneWidget);
  });

  testWidgets('Var olan kullanıcı bulunur', (tester) async {
    await tester.pumpWidget(buildApp());

    final searchField = find.byType(TextField);

    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'can35');

    // 450 ms debounce + Future tamamlanması
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('can35'), findsNWidgets(2));

    expect(find.text('Seçildi'), findsOneWidget);
  });

  testWidgets('Olmayan kullanıcı için hata gösterilir', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextField), 'olmayan123');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Bu kullanıcı bulunamadı.'), findsOneWidget);
  });

  testWidgets('Kullanıcı kendisini rakip seçemez', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextField), 'ahmet');

    await tester.pump();

    expect(find.text('Kendine oyun daveti gönderemezsin.'), findsOneWidget);
  });
}
