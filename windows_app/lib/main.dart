import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

void main() {
  runApp(const KelimeAnalizApp());
}

class KelimeAnalizApp extends StatelessWidget {
  const KelimeAnalizApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF10141B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kelime Arenası',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF36C58C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: background,
        cardTheme: const CardThemeData(
          color: Color(0xFF1A202A),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF242C38),
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const AnalysisScreen(),
    );
  }
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  static const _size = KelimelikBoard.size;
  final _rackController = TextEditingController();
  final _cells = List.generate(_size * _size, (_) => TextEditingController());

  TrieWordDictionary? _dictionary;
  List<GeneratedMove> _moves = const [];
  GeneratedMove? _selectedMove;
  GameSession? _session;
  TileBag? _tileBag;
  int _totalScore = 0;
  bool _loading = true;
  bool _searching = false;
  String? _message;
  int? _bonusRow;
  int? _bonusCol;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    try {
      final source = await rootBundle.loadString('assets/words.txt');
      final dictionary = TrieWordDictionary(source.split(RegExp(r'\r?\n')));
      if (!mounted) return;
      setState(() {
        _dictionary = dictionary;
        _loading = false;
        _message = '${dictionary.length} kelimelik sözlük hazır';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Sözlük açılamadı: $error';
      });
    }
  }

  Board _readBoard() {
    final bonus = _bonusRow != null && _bonusCol != null
        ? Position(_bonusRow!, _bonusCol!)
        : null;
    var board = KelimelikBoard.classic(bonus25: bonus);
    for (var row = 0; row < _size; row++) {
      for (var col = 0; col < _size; col++) {
        final raw = _cells[row * _size + col].text;
        final letter = tryNormalizeTurkishWord(raw);
        if (letter != null && letter.length == 1) {
          board = board.withTile(Position(row, col), Tile(letter: letter));
        }
      }
    }
    return board;
  }

  List<String>? _readRack() {
    final compact = _rackController.text.replaceAll(RegExp(r'[\s,]+'), '');
    final rack = <String>[];
    for (final rune in compact.runes) {
      final raw = String.fromCharCode(rune);
      if (raw == '?') {
        rack.add(raw);
        continue;
      }
      final letter = tryNormalizeTurkishWord(raw);
      if (letter == null || letter.length != 1) return null;
      rack.add(letter);
    }
    if (rack.isEmpty || rack.length > 7) return null;
    return rack;
  }

  Future<void> _analyze() async {
    final dictionary = _dictionary;
    final rack = _readRack();
    if (dictionary == null) {
      setState(() => _message = 'Sözlük henüz hazır değil.');
      return;
    }
    if (rack == null) {
      setState(() => _message = 'Eldeki 1–7 harfi gir. Joker için ? kullan.');
      return;
    }

    setState(() {
      _searching = true;
      _message = 'En iyi hamleler aranıyor…';
      _selectedMove = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 30));

    try {
      final watch = Stopwatch()..start();
      final moves = TrieMoveGenerator(dictionary: dictionary)
          .generate(board: _readBoard(), rack: rack, limit: 10);
      watch.stop();
      if (!mounted) return;
      setState(() {
        _moves = moves;
        _selectedMove = moves.isEmpty ? null : moves.first;
        _searching = false;
        _message = moves.isEmpty
            ? 'Bu harflerle yasal hamle bulunamadı.'
            : '${moves.length} hamle ${watch.elapsedMilliseconds} ms içinde bulundu';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _message = 'Tahta kontrol edilemedi: $error';
      });
    }
  }

  void _playSelectedMove() {
    final move = _selectedMove;
    final rack = _readRack();
    if (move == null || rack == null) {
      setState(() => _message = 'Önce elini girip bir hamle seç.');
      return;
    }
    try {
      final session = _session ??
          GameSession.newGame(
            board: _readBoard(),
            rack: rack,
          );
      final bag = _tileBag ?? TileBag();
      final next = session.playAndRefill(
        rack: rack,
        move: move,
        bag: bag,
      );
      for (final placement in move.placements) {
        _cells[placement.position.row * _size + placement.position.col].text =
            placement.letter;
      }
      _session = next;
      _tileBag = bag;
      _totalScore += move.score;
      _rackController.text = next.rack.join();
      setState(() {
        _moves = const [];
        _selectedMove = null;
        _message = '${move.word} oynandı: +${move.score} puan • '
            'Toplam: $_totalScore • ${next.turnCount}. hamle';
      });
    } catch (error) {
      setState(() => _message = 'Hamle oynanamadı: $error');
    }
  }

  void _analyzeFinishedGame() {
    final session = _session;
    final dictionary = _dictionary;
    if (session == null || session.turns.isEmpty || dictionary == null) {
      setState(() => _message = 'Analiz için en az bir hamle oyna.');
      return;
    }
    final generator = TrieMoveGenerator(dictionary: dictionary);
    final report = session.analyze(
      positionAnalyzer: PositionAnalyzer(moveGenerator: generator),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maç Analizi'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('${report.turns.length} hamle • Toplam puan: $_totalScore'),
              Text('Toplam kayıp: ${report.totalScoreLoss} puan'),
              Text('Ortalama verimlilik: %${(report.averageEfficiency * 100).round()}'),
              const Divider(),
              for (var i = 0; i < report.turns.length; i++)
                ListTile(
                  dense: true,
                  leading: Text('${i + 1}'),
                  title: Text('${report.turns[i].playedMove.word} → ${report.turns[i].bestMove.word}'),
                  subtitle: Text('${report.turns[i].playedMove.score} / ${report.turns[i].bestMove.score} puan • ${report.turns[i].quality.name}'),
                  trailing: Text('-${report.turns[i].scoreLoss}'),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('KAPAT'))],
      ),
    );
  }

  void _clearBoard() {
    for (final controller in _cells) {
      controller.clear();
    }
    setState(() {
      _moves = const [];
      _selectedMove = null;
      _bonusRow = null;
      _bonusCol = null;
      _message = 'Tahta temizlendi.';
    });
  }

  @override
  void dispose() {
    _rackController.dispose();
    for (final controller in _cells) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSide = constraints.maxHeight.clamp(
                      420.0,
                      constraints.maxWidth * .62,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: boardSide, child: _buildBoard()),
                        const SizedBox(width: 18),
                        Expanded(child: _buildControls()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF36C58C),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.grid_on_rounded, color: Color(0xFF10141B)),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            'Kelime Arenası',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            Text(
              'Türkçe kelime oyunu ve maç analizi',
              style: TextStyle(color: Color(0xFFA7B0BE)),
            ),
          ],
        ),
        const Spacer(),
        if (_loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        else
          const Icon(Icons.check_circle, color: Color(0xFF36C58C)),
        const SizedBox(width: 8),
        Text(_loading ? 'Sözlük yükleniyor' : 'Motor hazır'),
      ],
    );
  }

  Widget _buildBoard() {
    final premiumBoard = _premiumBoardForDisplay();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _size,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: _size * _size,
          itemBuilder: (context, index) {
            final position = Position(index ~/ _size, index % _size);
            final premium = premiumBoard.cellAt(position).premium;
            Placement? preview;
            for (final item
                in _selectedMove?.placements ?? const <Placement>[]) {
              if (item.position == position) {
                preview = item;
                break;
              }
            }
            return _BoardCell(
              controller: _cells[index],
              premium: premium,
              preview: preview,
            );
          },
        ),
      ),
    );
  }

  Board _premiumBoardForDisplay() {
    final bonus = _bonusRow != null && _bonusCol != null
        ? Position(_bonusRow!, _bonusCol!)
        : null;
    try {
      return KelimelikBoard.classic(bonus25: bonus);
    } on ArgumentError {
      return KelimelikBoard.classic();
    }
  }

  Widget _buildControls() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Eldeki Harfler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            TextField(
              key: const Key('rackField'),
              controller: _rackController,
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(7)],
              decoration: const InputDecoration(
                hintText: 'Örn. KALERTA',
                helperText: 'Joker taşı için ? yazabilirsin',
                counterText: '',
                prefixIcon: Icon(Icons.casino_outlined),
              ),
              onSubmitted: (_) => _analyze(),
            ),
            const SizedBox(height: 14),
            const Text(
              '+25 Bonus (isteğe bağlı)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _bonusDropdown(isRow: true)),
                const SizedBox(width: 8),
                Expanded(child: _bonusDropdown(isRow: false)),
                IconButton(
                  tooltip: 'Bonusu kaldır',
                  onPressed: _bonusRow == null && _bonusCol == null
                      ? null
                      : () => setState(() {
                          _bonusRow = null;
                          _bonusCol = null;
                        }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('analyzeButton'),
              onPressed: _loading || _searching ? null : _analyze,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('ANALİZ ET'),
              ),
            ),
            const SizedBox(height: 9),
            FilledButton.icon(
              key: const Key('playMoveButton'),
              onPressed: _selectedMove == null || _searching
                  ? null
                  : _playSelectedMove,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('SEÇİLİ HAMLEYİ OYNA'),
              ),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _clearBoard,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Tahtayı Temizle'),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              key: const Key('analyzeGameButton'),
              onPressed: _session == null || _session!.turns.isEmpty
                  ? null
                  : _analyzeFinishedGame,
              icon: const Icon(Icons.insights_rounded),
              label: const Text('OYUNU ANALİZ ET'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: const TextStyle(color: Color(0xFFA7B0BE))),
            ],
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 6),
            const Text(
              'En İyi Hamleler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _moves.isEmpty
                  ? const Center(
                      child: Text(
                        'Tahtayı ve harflerini girip\nAnaliz Et düğmesine bas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF7F8998)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _moves.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final move = _moves[index];
                        final selected = identical(move, _selectedMove);
                        return Material(
                          color: selected
                              ? const Color(0xFF24483D)
                              : const Color(0xFF242C38),
                          borderRadius: BorderRadius.circular(11),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            onTap: () => setState(() => _selectedMove = move),
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: selected
                                  ? const Color(0xFF36C58C)
                                  : const Color(0xFF343E4D),
                              foregroundColor: selected
                                  ? const Color(0xFF10141B)
                                  : Colors.white,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              move.word,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${move.start.row + 1}. satır, ${move.start.col + 1}. sütun • '
                              '${move.direction == Direction.horizontal ? 'Yatay' : 'Dikey'}',
                            ),
                            trailing: Text(
                              '${move.score}',
                              style: const TextStyle(
                                color: Color(0xFF64E2AE),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bonusDropdown({required bool isRow}) {
    final value = isRow ? _bonusRow : _bonusCol;
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isRow ? 'Satır' : 'Sütun',
        contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      ),
      items: List.generate(
        _size,
        (index) => DropdownMenuItem(value: index, child: Text('${index + 1}')),
      ),
      onChanged: (newValue) => setState(() {
        if (isRow) {
          _bonusRow = newValue;
        } else {
          _bonusCol = newValue;
        }
      }),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.controller,
    required this.premium,
    required this.preview,
  });

  final TextEditingController controller;
  final PremiumType premium;
  final Placement? preview;

  @override
  Widget build(BuildContext context) {
    final style = _premiumStyle(premium);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: preview == null ? style.color : const Color(0xFF36C58C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF0C1016), width: .7),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (style.label.isNotEmpty)
            Center(
              child: Text(
                style.label,
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: style.foreground.withValues(alpha: .78),
                ),
              ),
            ),
          TextField(
            controller: controller,
            maxLength: 1,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(1)],
            style: const TextStyle(
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              filled: false,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (preview != null)
            IgnorePointer(
              child: Center(
                child: Text(
                  preview!.letter,
                  style: const TextStyle(
                    color: Color(0xFF10241D),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _PremiumStyle _premiumStyle(PremiumType premium) {
    return switch (premium) {
      PremiumType.doubleLetter => const _PremiumStyle(
        Color(0xFF275A73),
        'H2',
        Colors.white,
      ),
      PremiumType.tripleLetter => const _PremiumStyle(
        Color(0xFF235E9B),
        'H3',
        Colors.white,
      ),
      PremiumType.doubleWord => const _PremiumStyle(
        Color(0xFF8B3E55),
        'K2',
        Colors.white,
      ),
      PremiumType.tripleWord => const _PremiumStyle(
        Color(0xFFB94A48),
        'K3',
        Colors.white,
      ),
      PremiumType.bonus25 => const _PremiumStyle(
        Color(0xFFD5A52B),
        '+25',
        Color(0xFF1A1710),
      ),
      PremiumType.none => const _PremiumStyle(
        Color(0xFF303947),
        '',
        Colors.white,
      ),
    };
  }
}

class _PremiumStyle {
  const _PremiumStyle(this.color, this.label, this.foreground);

  final Color color;
  final String label;
  final Color foreground;
}
