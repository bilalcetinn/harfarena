import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

class GameResultView extends StatelessWidget {
  const GameResultView({
    required this.myName,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.didWin,
    required this.isDraw,
    required this.finishedByForfeit,
    required this.totalMoves,
    required this.durationText,
    required this.bestMoveWord,
    required this.bestMoveScore,
    required this.modeLabel,
    required this.canAnalyze,
    required this.busy,
    required this.onAnalyze,
    required this.onRematch,
    required this.onHome,
    super.key,
  });

  final String myName;
  final String opponentName;
  final int myScore;
  final int opponentScore;

  /// Sonuç sadece skordan türetilmez. Manuel "Maçı Bitir" işlemi
  /// pes etme olduğu için sonucu lobby belirler.
  final bool didWin;
  final bool isDraw;
  final bool finishedByForfeit;

  final int totalMoves;
  final String durationText;
  final String bestMoveWord;
  final int bestMoveScore;
  final String modeLabel;

  final bool canAnalyze;
  final bool busy;

  final VoidCallback onAnalyze;
  final VoidCallback onRematch;
  final VoidCallback onHome;

  static const _brandDark = AppColors.brandGreenDark;
  static const _brandGreen = AppColors.brandGreen;

  static const _page = Color(0xFFF5F7F8);
  static const _card = Colors.white;
  static const _text = Color(0xFF142019);
  static const _muted = Color(0xFF6C7470);
  static const _border = Color(0xFFE5E8E6);
  static const _blue = Color(0xFF5DA9F6);
  static const _orange = Color(0xFFF0A426);

  bool get _isDraw => isDraw;
  bool get _didWin => didWin;

  String get _resultTitle {
    if (_isDraw) return 'BERABERE';
    return _didWin ? 'KAZANDIN! 🎉' : 'KAYBETTİN';
  }

  String get _resultKicker {
    if (_isDraw) return 'MAÇ TAMAMLANDI';

    if (finishedByForfeit) {
      return _didWin ? 'RAKİP PES ETTİ' : 'MAÇTAN ÇEKİLDİN';
    }

    return _didWin ? 'TEBRİKLER' : 'İYİ MÜCADELE';
  }

  String get _resultSubtitle {
    if (_isDraw) {
      return 'Arenadan eşit puanla ayrıldınız.';
    }

    if (finishedByForfeit) {
      return _didWin
          ? 'Rakibin maçı bitirdiği için galip geldin.'
          : 'Maçı bitirdiğin için rakibin galip sayıldı.';
    }

    if (_didWin) {
      return 'Harika bir stratejiyle maçı kazandın';
    }

    return 'Bu maçta rakibin öne geçti. Rövanş zamanı!';
  }

  int get _difference => (myScore - opponentScore).abs();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _brandDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _page,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      // Android edge-to-edge modunda statusBarColor tek başına
      // yeterli olmayabiliyor. SafeArea'nın arkasını da yeşile boyuyoruz.
      child: ColoredBox(
        color: _brandDark,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ColoredBox(
            color: _page,
            child: Column(
              children: [
                MainSectionHeader(
                  title: 'Oyun Sonucu',
                  subtitle: 'Maç özetini incele, analiz et veya rövanş iste.',
                  icon: Icons.emoji_events_rounded,
                  onBack: onHome,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    children: [
                      _VictoryBanner(
                        kicker: _resultKicker,
                        title: _resultTitle,
                        subtitle: _resultSubtitle,
                        won: _didWin,
                        draw: _isDraw,
                      ),
                      const SizedBox(height: 12),
                      _PlayersCard(
                        myName: myName,
                        opponentName: opponentName,
                        myScore: myScore,
                        opponentScore: opponentScore,
                        didWin: _didWin,
                        isDraw: _isDraw,
                        difference: _difference,
                      ),
                      const SizedBox(height: 12),
                      _MatchSummaryCard(
                        totalMoves: totalMoves,
                        durationText: durationText,
                        bestMoveWord: bestMoveWord,
                        bestMoveScore: bestMoveScore,
                        modeLabel: modeLabel,
                      ),
                      const SizedBox(height: 12),
                      const _AnalysisPromoCard(),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: !canAnalyze || busy ? null : onAnalyze,
                          icon: const Icon(Icons.bar_chart_rounded, size: 21),
                          label: const Text('ANALİZ ET'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandDark,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _brandDark.withValues(
                              alpha: 0.35,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : onRematch,
                          icon: const Icon(Icons.sync_rounded, size: 19),
                          label: const Text('Rövanş İste'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _text,
                            side: const BorderSide(color: _border, width: 1.2),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextButton(
                        onPressed: busy ? null : onHome,
                        style: TextButton.styleFrom(
                          foregroundColor: _muted,
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Ana Sayfaya Dön'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VictoryBanner extends StatelessWidget {
  const _VictoryBanner({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.won,
    required this.draw,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final bool won;
  final bool draw;

  @override
  Widget build(BuildContext context) {
    final _ResultBannerPalette palette;

    if (won) {
      palette = const _ResultBannerPalette(
        accent: Color(0xFF14833B),
        backgroundStart: Color(0xFFF7FFF8),
        backgroundEnd: Color(0xFFEAF8ED),
        border: Color(0xFFAFE0B8),
        chipBackground: Color(0xFFDDF2E2),
        icon: Icons.check_circle_rounded,
        dotOne: Color(0xFFF1C743),
        dotTwo: Color(0xFF63D6A8),
        dotThree: Color(0xFF8CBFF9),
      );
    } else if (draw) {
      palette = const _ResultBannerPalette(
        accent: Color(0xFF52758E),
        backgroundStart: Color(0xFFF8FBFD),
        backgroundEnd: Color(0xFFEDF3F7),
        border: Color(0xFFC7D8E3),
        chipBackground: Color(0xFFE4EEF4),
        icon: Icons.handshake_rounded,
        dotOne: Color(0xFFF1C743),
        dotTwo: Color(0xFF7FB6D8),
        dotThree: Color(0xFFAC9BE8),
      );
    } else {
      // Kayıp ekranında artık yeşil başarı kartı kullanılmıyor.
      // HarfArena'nın koyu yeşil app barı korunurken sonuç kartı
      // sıcak kırmızı / mercan tonlarıyla net şekilde ayrılıyor.
      palette = const _ResultBannerPalette(
        accent: Color(0xFFC84A3D),
        backgroundStart: Color(0xFFFFFAF8),
        backgroundEnd: Color(0xFFFFEEEA),
        border: Color(0xFFF0B6AD),
        chipBackground: Color(0xFFF9DDD8),
        icon: Icons.flag_rounded,
        dotOne: Color(0xFFF1B24A),
        dotTwo: Color(0xFFE97C6F),
        dotThree: Color(0xFF94B7E8),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.backgroundStart, palette.backgroundEnd],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.055),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 1,
            child: _ConfettiDot(color: palette.dotOne, size: 5),
          ),
          Positioned(
            top: 0,
            right: 1,
            child: _ConfettiDot(color: palette.dotTwo, size: 7),
          ),
          Positioned(
            bottom: 0,
            right: 16,
            child: _ConfettiDot(color: palette.dotThree, size: 7),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.chipBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(palette.icon, size: 12, color: palette.accent),
                      const SizedBox(width: 5),
                      Text(
                        kicker,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameResultView._muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBannerPalette {
  const _ResultBannerPalette({
    required this.accent,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.border,
    required this.chipBackground,
    required this.icon,
    required this.dotOne,
    required this.dotTwo,
    required this.dotThree,
  });

  final Color accent;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color border;
  final Color chipBackground;
  final IconData icon;
  final Color dotOne;
  final Color dotTwo;
  final Color dotThree;
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({
    required this.myName,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.didWin,
    required this.isDraw,
    required this.difference,
  });

  final String myName;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final bool didWin;
  final bool isDraw;
  final int difference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: GameResultView._card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GameResultView._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _PlayerResult(
              name: myName,
              score: myScore,
              isMe: true,
              winner: isDraw || didWin,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 37,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Color(0xFFB8BEBA),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  difference == 0 ? 'Eşit' : '+$difference fark',
                  style: const TextStyle(
                    color: GameResultView._muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _PlayerResult(
              name: opponentName,
              score: opponentScore,
              isMe: false,
              winner: isDraw || !didWin,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerResult extends StatelessWidget {
  const _PlayerResult({
    required this.name,
    required this.score,
    required this.isMe,
    required this.winner,
  });

  final String name;
  final int score;
  final bool isMe;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PlayerAvatar(
              username: name,
              radius: 24,
              backgroundColor: isMe
                  ? const Color(0xFFFFE7D1)
                  : const Color(0xFFE4EFFF),
              foregroundColor: isMe
                  ? const Color(0xFF8D4E2F)
                  : const Color(0xFF36588F),
              borderColor: winner
                  ? GameResultView._brandGreen
                  : Colors.transparent,
              borderWidth: 1.2,
            ),
            Positioned(
              right: -2,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isMe
                      ? GameResultView._brandGreen
                      : const Color(0xFF4C6FAE),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  isMe ? 'Sen' : 'Rakip',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GameResultView._text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$score',
              style: TextStyle(
                color: winner
                    ? GameResultView._brandDark
                    : const Color(0xFF46504B),
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                'puan',
                style: TextStyle(
                  color: GameResultView._muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: winner ? const Color(0xFFE5F4E7) : const Color(0xFFFBE7E4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            winner ? 'Galip' : 'Mağlup',
            style: TextStyle(
              color: winner
                  ? GameResultView._brandGreen
                  : const Color(0xFFC84A3D),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchSummaryCard extends StatelessWidget {
  const _MatchSummaryCard({
    required this.totalMoves,
    required this.durationText,
    required this.bestMoveWord,
    required this.bestMoveScore,
    required this.modeLabel,
  });

  final int totalMoves;
  final String durationText;
  final String bestMoveWord;
  final int bestMoveScore;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: GameResultView._card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GameResultView._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 17,
                color: GameResultView._brandGreen,
              ),
              const SizedBox(width: 6),
              const Text(
                'Maç Özeti',
                style: TextStyle(
                  color: GameResultView._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    color: Color(0xFF8B92A0),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Divider(height: 1, color: GameResultView._border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Toplam Hamle',
                  child: Text(
                    '$totalMoves',
                    style: const TextStyle(
                      color: GameResultView._text,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCell(
                  label: 'Oyun Süresi',
                  child: Text(
                    durationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameResultView._text,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'En İyi Kelimen',
                  child: _WordTiles(word: bestMoveWord),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCell(
                  label: 'En Yüksek Hamle',
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: bestMoveScore <= 0 ? '—' : '+$bestMoveScore',
                          style: const TextStyle(
                            color: GameResultView._brandGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (bestMoveScore > 0)
                          const TextSpan(
                            text: ' puan',
                            style: TextStyle(
                              color: GameResultView._brandGreen,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameResultView._muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _WordTiles extends StatelessWidget {
  const _WordTiles({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    if (word.trim().isEmpty) {
      return const Text(
        '—',
        style: TextStyle(
          color: GameResultView._text,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    final letters = word
        .trim()
        .toUpperCase()
        .split('')
        .take(7)
        .toList(growable: false);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < letters.length; index++) ...[
            if (index > 0) const SizedBox(width: 2),
            Container(
              width: 18,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7AE),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE0B765)),
              ),
              child: Text(
                letters[index],
                style: const TextStyle(
                  color: Color(0xFF4C3420),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisPromoCard extends StatelessWidget {
  const _AnalysisPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5FFF6), Color(0xFFEAF8ED)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8DD49A)),
        boxShadow: [
          BoxShadow(
            color: GameResultView._brandGreen.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: GameResultView._brandDark,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Maçını Analiz Et',
                          style: TextStyle(
                            color: GameResultView._text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 6),
                        _NewChip(),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hamlelerini incele, kaçırdığın fırsatları gör ve en iyi kelimeleri keşfet.',
                      style: TextStyle(
                        color: Color(0xFF355143),
                        fontSize: 10.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFCDEBD2)),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 9,
            runSpacing: 5,
            children: [
              _LegendItem(color: Color(0xFF30CF96), text: 'Hamle Doğruluğu'),
              _LegendItem(
                color: GameResultView._orange,
                text: 'Kaçan Fırsatlar',
              ),
              _LegendItem(
                color: GameResultView._blue,
                text: 'Tahta Hakimiyeti',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewChip extends StatelessWidget {
  const _NewChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: GameResultView._brandGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'YENİ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF355143),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
