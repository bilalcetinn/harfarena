# Turkish Word Engine — MVP 0.5

Türkçe 15x15 kelime oyunları için bağımsız, kural tabanlı hamle üretme ve oyun analizi motoru.

## V0.2 ile gelenler

- 15x15 tahta ve 7 taşlık rack
- İlk hamlede merkez zorunluluğu
- Mevcut taşlara temas ve yan kelime doğrulama
- H2 / H3 / K2 / K3
- Joker (`?`) desteği ve joker için 0 puan
- +25 bonus hücresi
- 7 taş kullanımında +30 puan
- `TrieWordDictionary`
- Trie tabanlı hamle üretimi
- Perpendicular cross-check kümeleri
- En yüksek puanlı N hamleyi sıralama
- Oynanan hamleyi en iyi hamleyle karşılaştıran `PositionAnalyzer`
- Puan kaybı, anlık verimlilik ve hamle kalite sınıflandırması
- Birden fazla turu sırayla analiz eden `GameAnalyzer`
- Harici kelime listesini normalize eden `tool/build_dictionary.dart`

## V0.3 ile gelenler

- Gerçek 15x15 klasik Kelimelik H2/H3/K2/K3 yerleşimi
- K2 olarak puanlanan merkez yıldız hücresi
- Oyuna özel rastgele +25 hücresi ekleyebilen `KelimelikBoard.classic()`
- Tahta düzeninin hücre sayısı, simetrisi ve açılış puanı testleri
- 62.025 kelimelik temizlenmiş Türkçe başlangıç sözlüğü
- Dosyadan Trie sözlüğü yükleyen `DictionaryLoader`

## V0.4 ile gelenler

- Dışarıdan gelen hamleyi sözlük, tahta, rack ve bağlantı kurallarıyla
  doğrulayan `MoveValidator`
- Kullanıcıdan gelen puanı güvenilir saymak yerine yeniden hesaplayan analiz
- Geçersiz yan kelime, eksik/fazla yerleşim, çakışma ve merkez dışı açılış
  kontrolleri
- Yedi taştan büyük rack girdilerini erken reddeden koruma

## V0.5 ile gelenler

- Windows için görsel `Kelime Analiz` uygulaması
- Gerçek 15x15 premium tahta üzerinde mevcut harfleri elle girebilme
- Elde kalan 1–7 harf ve joker (`?`) ile en iyi 10 hamleyi arama
- Seçilen hamleyi tahta üzerinde yeşil önizleme olarak gösterme
- İsteğe bağlı +25 bonus hücresini satır/sütun olarak seçme
- Sözlüğü uygulama içinde taşıyan, ayrıca dosya seçtirmeyen paketleme
- Aynı Masaüstü kurulumunu yenileyen `uygulamayi_guncelle.bat`

## Mobil ürün hedefi

Asıl ürün `mobile_app` klasöründeki Android uygulamasıdır. Masaüstü arayüzü
yalnızca motoru geliştirirken tahtayı ve puanları hızlı doğrulamak için kullanılan
bir test aracıdır.

Android uygulamasında şu anda:

- 62.025 kelimelik Trie motoru ve gerçek tahta kuralları uygulamanın içindedir.
- Kullanıcıdan ekran üstü gösterim ve Android ekran yakalama izinleri alınır.
- Foreground MediaProjection servisi ekranı canlı yakalar ve son kareyi güvenli
  biçimde uygulamanın önbelleğine yazar.
- Kelimelik üzerinde yakalamanın sürdüğünü gösteren küçük bir durum balonu vardır.

Sıradaki geliştirme, gerçek telefon ekran görüntüleriyle 15×15 tahta alanını
kalibre etmek, hücre harflerini tanımak ve motor sonucunu yüzen panelde
göstermektir.

## Windows geliştirme aracını kullanma

Masaüstündeki **Kelime Analiz** kısayoluna çift tıklayın. Oyunda tahtada
bulunan harfleri aynı hücrelere yazın, elinizdeki taşları sağdaki alana girin
ve **ANALİZ ET** düğmesine basın. Joker taşı `?` ile gösterilir. Sonuçlardan
birine tıklanınca yeni konulacak taşlar tahtada yeşil görünür.

Kaynak kod değiştirildikten sonra Masaüstündeki
`turkish_word_engine\uygulamayi_guncelle.bat` dosyası çalıştırılarak kurulu
uygulama aynı konumda güncellenebilir.

## Neden model değil?

V0.x çekirdeği deterministiktir: tüm yasal hamleleri üretir ve resmi puan kurallarıyla puanlar. ML/Monte Carlo daha sonra rack leave, rakibe açılan alan ve kazanma olasılığı gibi pozisyonel değerler için eklenebilir.

## Sözlük stratejisi

Kelimelik TDK Güncel Türkçe Sözlüğü'nü referans aldığını, fakat kendi listesinin birebir aynı olmadığını açıkça belirtiyor. Bu nedenle motor herhangi bir özel Kelimelik veritabanını paketlemez. Sözlük bağımsız bir katmandır.

Açık bir kelime listesini hazırlamak için:

```bash
dart run tool/build_dictionary.dart source_words.txt assets/words.txt
```

Dönüştürücü boşluk/noktalama içeren girdileri ve 15 harften uzun kelimeleri eler, Türkçe büyük harfe normalize eder ve tekilleştirir.

## Kullanım

```dart
final dictionary = await DictionaryLoader.loadTrie('assets/words.txt');

final engine = TrieMoveGenerator(dictionary: dictionary);
final board = KelimelikBoard.classic();

// Oyunda +25 hücresi görünüyorsa koordinatını ayrıca verin:
// final board = KelimelikBoard.classic(
//   bonus25: const Position(7, 6),
// );

final moves = engine.generate(
  board: board,
  rack: const ['K', 'A', 'L', 'E', 'R', 'T', 'A'],
  limit: 10,
);
```

## Stockfish-benzeri pozisyon analizi

```dart
final analyzer = PositionAnalyzer(moveGenerator: engine);

final result = analyzer.analyze(
  board: board,
  rack: const ['K', 'A', 'L', 'E', 'R', 'T', 'A'],
  playedMove: playedMove,
);

print(result.bestMove);
print(result.scoreLoss);
print(result.efficiency);
print(result.quality);
```

Şimdilik kalite yalnızca anlık puan kaybına göre hesaplanır. İleriki sürümlerde rack leave + board control + Monte Carlo ile stratejik değerlendirme eklenecek.

## Çalıştırma

Gereksinim: Dart SDK 3.3 veya daha yeni bir 3.x sürümü.

```bash
dart pub get
dart analyze
dart test
dart run example/main.dart
```

## Doğrulama durumu

Bu paket Dart statik analizinden hatasız geçer. Test paketi şu alanları kapsar:

- temel harf puanları, merkez kuralı, joker ve 7 taş bonusu
- yeni konulan taşın kelime ve harf çarpanları
- aynı hamlede ana kelime ile yan kelimenin birlikte puanlanması
- Trie önek araması, mevcut kelimeyi uzatma ve cross-check filtreleri
- Trie üreticinin temsilî pozisyonlarda exhaustive referans üreticiyle eşleşmesi
- gerçek sözlük dosyasının 62.025 kelimeyle yüklenmesi
- oynanan hamlenin yeniden puanlanması ve geçersiz hamlelerin reddedilmesi
- puan kaybı sınıflandırması ve hamle uygulanırken dolu hücre koruması

## MVP için kalan işler

- Pas, taş değiştirme, torba ve oyun sonu ceza/bonuslarını oyun geçmişi modeline
  eklemek.
- Büyük sözlükte süre/bellek benchmarkı kurmak. Mevcut üretici Trie ve cross-check
  kullanır, ancak henüz anchor-square/GADDAG düzeyinde optimize değildir.

## Bağımsızlık

Bu proje Kelimelik istemci koduna, özel API'lerine veya özel kelime veritabanına erişmez. Kurallar bağımsız şekilde modellenmiştir.

Paketlenen başlangıç sözlüğünün kaynak ve lisans bilgisi
`THIRD_PARTY_NOTICES.md` dosyasında yer alır. Bu liste Kelimelik'in özel
veritabanı değildir ve oyunla birebir eşleşmesi garanti edilmez.
