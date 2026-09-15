import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/analysis/models/word_definition.dart';
import 'package:kelime_analiz_mobile/domain/analysis/repositories/word_definition_repository.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

import 'package:turkish_word_engine/turkish_word_engine.dart';

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({
    super.key,
    required this.initialBoard,
    required this.turns,
    required this.report,
    required this.turnIsMine,
    required this.myName,
    required this.opponentName,
    required this.definitions,
  });

  final Board initialBoard;
  final List<GameTurn> turns;
  final GameAnalysisReport report;

  /// Her analiz hamlesinin mevcut kullanıcıya ait olup olmadığını belirtir.
  /// turns/report.turns ile aynı sırada olmalıdır.
  final List<bool> turnIsMine;

  final String myName;
  final String opponentName;
  final WordDefinitionRepository definitions;

  @override
  State<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends State<MatchAnalysisScreen> {
  static const _brandDark = AppColors.brandGreenDark;
  static const _brandGreen = AppColors.brandGreen;
  static const _page = Color(0xFFF5F7F8);
  static const _card = Colors.white;
  static const _text = Color(0xFF172019);
  static const _muted = Color(0xFF737B76);
  static const _border = Color(0xFFE4E8E5);

  late final List<Board> _boardsBefore;

  final TransformationController _boardController = TransformationController();

  Offset? _doubleTapPosition;

  int _index = 0;
  bool _showBest = false;

  @override
  void initState() {
    super.initState();

    var board = widget.initialBoard;
    _boardsBefore = [];

    for (final turn in widget.turns) {
      _boardsBefore.add(board);
      board = board.applyMove(turn.playedMove);
    }
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.report.turns.isEmpty) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: _brandDark,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: _page,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _page,
          body: SafeArea(
            top: false,
            bottom: false,
            child: ColoredBox(
              color: _page,
              child: Column(
                children: [
                  MainSectionHeader(
                    title: 'Maç Analizi',
                    subtitle: 'Hamlelerini incele, en iyi alternatifleri ve verimliliğini karşılaştır.',
                    icon: Icons.analytics_rounded,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Analiz edilecek hamle bulunamadı.',
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final analysis = widget.report.turns[_index];

    final isMyTurn = _index < widget.turnIsMine.length
        ? widget.turnIsMine[_index]
        : true;

    final playerName = isMyTurn ? widget.myName : widget.opponentName;

    final playerColor = isMyTurn ? _brandGreen : const Color(0xFF3979C7);

    final myAverageEfficiency = _calculateMyAverageEfficiency();

    final selectedMove = _showBest ? analysis.bestMove : analysis.playedMove;

    final screen = MediaQuery.sizeOf(context);

    final boardSize = max(245.0, min(screen.width - 20, screen.height * 0.49));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _brandDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _page,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // SafeArea'nın üstünde kalan telefon status alanını
        // gerçekten yeşile boyamak için scaffold zemini yeşil.
        backgroundColor: _brandDark,
        body: SafeArea(
          top: false,
          bottom: false,
          child: ColoredBox(
            color: _page,
            child: Column(
              children: [
                MainSectionHeader(
                  title: 'Maç Analizi',
                  subtitle: 'Hamlelerini incele, en iyi alternatifleri ve verimliliğini karşılaştır.',
                  icon: Icons.analytics_rounded,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                    children: [
                      _OverallSummary(
                        current: _index + 1,
                        total: widget.report.turns.length,
                        efficiency: myAverageEfficiency,
                        isMine: isMyTurn,
                        playerName: playerName,
                        playerColor: playerColor,
                      ),
                      const SizedBox(height: 10),

                      Center(
                        child: Container(
                          width: boardSize,
                          height: boardSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8B27F),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTapDown: (details) {
                              _doubleTapPosition = details.localPosition;
                            },
                            onDoubleTap: _toggleBoardZoom,
                            child: InteractiveViewer(
                              transformationController: _boardController,
                              alignment: Alignment.topLeft,
                              minScale: 1,
                              maxScale: 5,
                              panEnabled: true,
                              scaleEnabled: true,
                              constrained: true,
                              boundaryMargin: EdgeInsets.zero,
                              clipBehavior: Clip.hardEdge,
                              child: _AnalysisBoard(
                                board: _boardsBefore[_index],
                                preview: selectedMove,
                                best: _showBest,
                                playedColor: playerColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _MoveComparisonCard(
                        playedMove: analysis.playedMove,
                        bestMove: analysis.bestMove,
                        showBest: _showBest,
                        isMine: isMyTurn,
                        playerName: playerName,
                        playedColor: playerColor,
                        onPlayedTap: () {
                          _resetBoardZoom();
                          setState(() {
                            _showBest = false;
                          });
                        },
                        onBestTap: () {
                          _resetBoardZoom();
                          setState(() {
                            _showBest = true;
                          });
                        },
                        onPlayedDefinitionTap: () =>
                            _showDefinition(analysis.playedMove.word),
                        onBestDefinitionTap: () =>
                            _showDefinition(analysis.bestMove.word),
                      ),

                      const SizedBox(height: 10),

                      _QualityCard(
                        title: _qualityName(analysis.quality),
                        color: _qualityColor(analysis.quality),
                        scoreLoss: analysis.scoreLoss,
                        playedScore: analysis.playedMove.score,
                        bestScore: analysis.bestMove.score,
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _index == 0 ? null : _previous,
                              icon: const Icon(Icons.chevron_left_rounded),
                              label: const Text('ÖNCEKİ'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: _brandDark,
                                side: const BorderSide(
                                  color: _brandDark,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _index == widget.report.turns.length - 1
                                  ? null
                                  : _next,
                              icon: const Icon(Icons.chevron_right_rounded),
                              label: const Text('SONRAKİ'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: _brandDark,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _brandDark.withValues(
                                  alpha: 0.30,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  double _calculateMyAverageEfficiency() {
    final turnCount = min(widget.report.turns.length, widget.turnIsMine.length);
    var total = 0.0;
    var myTurnCount = 0;

    for (var index = 0; index < turnCount; index++) {
      if (!widget.turnIsMine[index]) continue;

      final analysis = widget.report.turns[index];
      final bestScore = analysis.bestMove.score;
      final playedScore = analysis.playedMove.score;

      final efficiency = bestScore <= 0
          ? 1.0
          : (playedScore / bestScore).clamp(0.0, 1.0).toDouble();

      total += efficiency;
      myTurnCount++;
    }

    if (myTurnCount == 0) return 0;
    return total / myTurnCount;
  }

  void _previous() {
    if (_index == 0) return;

    _resetBoardZoom();

    setState(() {
      _index--;
      _showBest = false;
    });
  }

  void _next() {
    if (_index >= widget.report.turns.length - 1) {
      return;
    }

    _resetBoardZoom();

    setState(() {
      _index++;
      _showBest = false;
    });
  }

  void _resetBoardZoom() {
    _boardController.value = Matrix4.identity();
  }

  void _toggleBoardZoom() {
    final zoomed = _boardController.value.getMaxScaleOnAxis() > 1.05;

    if (zoomed) {
      _resetBoardZoom();
      return;
    }

    const scale = 2.35;
    final focalPoint = _doubleTapPosition ?? Offset.zero;

    final matrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, (1 - scale) * focalPoint.dx)
      ..setEntry(1, 3, (1 - scale) * focalPoint.dy);

    _boardController.value = matrix;
  }

  Future<WordDefinition> _lookupDefinitionSafely(String word) async {
    try {
      return await widget.definitions.lookup(word);
    } catch (_) {
      return WordDefinition(word: word, meanings: const []);
    }
  }

  Future<void> _showDefinition(String word) async {
    final normalized = word.trim().toUpperCase();
    if (normalized.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF4),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                normalized,
                style: const TextStyle(
                  color: Color(0xFF173B2A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Kapat',
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: FutureBuilder<WordDefinition>(
            future: _lookupDefinitionSafely(normalized),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final meanings = snapshot.data?.meanings ?? const <String>[];
              if (meanings.isEmpty) {
                return const Text(
                  'TDK’da anlam bulunamadı veya bağlantı kurulamadı.',
                  style: TextStyle(color: Color(0xFF5F625E), fontSize: 13),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: meanings.length,
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '${index + 1}. ${meanings[index]}',
                      style: const TextStyle(
                        color: Color(0xFF343733),
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _qualityName(MoveQuality quality) => switch (quality) {
    MoveQuality.best => 'EN İYİ HAMLE',
    MoveQuality.excellent => 'MÜKEMMEL',
    MoveQuality.good => 'İYİ HAMLE',
    MoveQuality.inaccuracy => 'HATALI',
    MoveQuality.mistake => 'HATA',
    MoveQuality.blunder => 'BÜYÜK HATA',
  };

  Color _qualityColor(MoveQuality quality) => switch (quality) {
    MoveQuality.best => const Color(0xFF168B72),
    MoveQuality.excellent => const Color(0xFF3A9D72),
    MoveQuality.good => const Color(0xFF5F8D3E),
    MoveQuality.inaccuracy => const Color(0xFFBF8C22),
    MoveQuality.mistake => const Color(0xFFD56B32),
    MoveQuality.blunder => const Color(0xFFC83D45),
  };
}

class _OverallSummary extends StatelessWidget {
  const _OverallSummary({
    required this.current,
    required this.total,
    required this.efficiency,
    required this.isMine,
    required this.playerName,
    required this.playerColor,
  });

  final int current;
  final int total;
  final double efficiency;
  final bool isMine;
  final String playerName;
  final Color playerColor;

  @override
  Widget build(BuildContext context) {
    final percentage = (efficiency * 100).round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _MatchAnalysisScreenState._card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _MatchAnalysisScreenState._border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: _MatchAnalysisScreenState._brandGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$current / $total. hamle',
                      style: const TextStyle(
                        color: _MatchAnalysisScreenState._text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: playerColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: playerColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        isMine ? 'SENİN HAMLEN' : 'RAKİBİN HAMLESİ',
                        style: TextStyle(
                          color: playerColor,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$playerName • En iyi alternatifle karşılaştır',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _MatchAnalysisScreenState._muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '%$percentage',
                style: const TextStyle(
                  color: _MatchAnalysisScreenState._brandDark,
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'senin verimliliğin',
                style: TextStyle(
                  color: _MatchAnalysisScreenState._muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoveComparisonCard extends StatelessWidget {
  const _MoveComparisonCard({
    required this.playedMove,
    required this.bestMove,
    required this.showBest,
    required this.isMine,
    required this.playerName,
    required this.playedColor,
    required this.onPlayedTap,
    required this.onBestTap,
    required this.onPlayedDefinitionTap,
    required this.onBestDefinitionTap,
  });

  final GeneratedMove playedMove;
  final GeneratedMove bestMove;
  final bool showBest;
  final bool isMine;
  final String playerName;
  final Color playedColor;
  final VoidCallback onPlayedTap;
  final VoidCallback onBestTap;
  final VoidCallback onPlayedDefinitionTap;
  final VoidCallback onBestDefinitionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _MatchAnalysisScreenState._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _MatchAnalysisScreenState._border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MoveChoice(
              label: isMine ? 'SENİN HAMLEN' : 'RAKİBİN HAMLESİ',
              subtitle: playerName,
              move: playedMove,
              selected: !showBest,
              color: playedColor,
              onTap: onPlayedTap,
              onDefinitionTap: onPlayedDefinitionTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MoveChoice(
              label: 'EN İYİ HAMLE',
              subtitle: 'Bu pozisyon için',
              move: bestMove,
              selected: showBest,
              color: const Color(0xFFF0A426),
              onTap: onBestTap,
              onDefinitionTap: onBestDefinitionTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveChoice extends StatelessWidget {
  const _MoveChoice({
    required this.label,
    required this.subtitle,
    required this.move,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.onDefinitionTap,
  });

  final String label;
  final String subtitle;
  final GeneratedMove move;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDefinitionTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? color
                          : _MatchAnalysisScreenState._muted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MatchAnalysisScreenState._muted,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              move.word.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MatchAnalysisScreenState._text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${move.score} puan',
                  style: TextStyle(
                    color: selected ? color : _MatchAnalysisScreenState._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Kelimenin anlamını göster',
                  child: InkResponse(
                    onTap: onDefinitionTap,
                    radius: 15,
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(
                        Icons.question_mark_rounded,
                        size: 14,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({
    required this.title,
    required this.color,
    required this.scoreLoss,
    required this.playedScore,
    required this.bestScore,
  });

  final String title;
  final Color color;
  final int scoreLoss;
  final int playedScore;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    final noLoss = scoreLoss <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              noLoss ? Icons.check_rounded : Icons.insights_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  noLoss
                      ? 'Bu pozisyonda en iyi hamleyi buldun.'
                      : '$scoreLoss puanlık fırsat kaçtı.',
                  style: const TextStyle(
                    color: _MatchAnalysisScreenState._text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$playedScore → $bestScore',
                style: const TextStyle(
                  color: _MatchAnalysisScreenState._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'puan',
                style: TextStyle(
                  color: _MatchAnalysisScreenState._muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisBoard extends StatelessWidget {
  const _AnalysisBoard({
    required this.board,
    required this.preview,
    required this.best,
    required this.playedColor,
  });

  final Board board;
  final GeneratedMove preview;
  final bool best;
  final Color playedColor;

  static const _gridGap = 1.15;

  @override
  Widget build(BuildContext context) {
    final previewByPosition = {
      for (final placement in preview.placements) placement.position: placement,
    };

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 15,
          mainAxisSpacing: _gridGap,
          crossAxisSpacing: _gridGap,
        ),
        itemCount: 225,
        itemBuilder: (context, index) {
          final position = Position(index ~/ 15, index % 15);

          final tile = board.tileAt(position);

          final placed = previewByPosition[position];

          final premium = board.cellAt(position).premium;

          final letter = tile?.letter ?? placed?.letter;

          final blank = tile?.isBlank == true || placed?.isBlank == true;

          final isPreview = placed != null;

          final cellColor = isPreview
              ? best
                    ? const Color(0xFFF2A938)
                    : playedColor
              : tile != null
              ? const Color(0xFFFFE2A0)
              : _premiumColor(premium);

          return Container(
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(4.8),
              border: isPreview
                  ? Border.all(
                      color: best
                          ? const Color(0xFFB86F00)
                          : Color.lerp(playedColor, Colors.black, 0.22)!,
                      width: 1.2,
                    )
                  : null,
            ),
            child: letter == null
                ? Text(
                    _premiumLabel(premium),
                    style: TextStyle(
                      color: _premiumTextColor(premium),
                      fontSize: 6.6,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          letter.toUpperCase(),
                          style: TextStyle(
                            color: isPreview
                                ? Colors.white
                                : const Color(0xFF3A2D20),
                            fontSize: 14,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Text(
                          '${blank ? 0 : const KelimeRules().pointsFor(letter)}',
                          style: TextStyle(
                            color: isPreview
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF5D4A2A),
                            fontSize: 5.7,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  static Color _premiumColor(PremiumType premium) => switch (premium) {
    PremiumType.doubleLetter => const Color(0xFFDCEFE3),
    PremiumType.tripleLetter => const Color(0xFF86BC98),
    PremiumType.doubleWord => const Color(0xFFC5DFAE),
    PremiumType.tripleWord => const Color(0xFF4A9363),
    PremiumType.bonus25 => const Color(0xFFA9CF78),
    PremiumType.none => const Color(0xFFE7E9E3),
  };

  static Color _premiumTextColor(PremiumType premium) => switch (premium) {
    PremiumType.doubleLetter => const Color(0xFF2E6240),
    PremiumType.tripleLetter => const Color(0xFF164A2C),
    PremiumType.doubleWord => const Color(0xFF365E25),
    PremiumType.tripleWord => Colors.white,
    PremiumType.bonus25 => const Color(0xFF365A1F),
    PremiumType.none => Colors.transparent,
  };

  static String _premiumLabel(PremiumType premium) => switch (premium) {
    PremiumType.doubleLetter => 'H2',
    PremiumType.tripleLetter => 'H3',
    PremiumType.doubleWord => 'K2',
    PremiumType.tripleWord => 'K3',
    PremiumType.bonus25 => '+25',
    PremiumType.none => '',
  };
}
