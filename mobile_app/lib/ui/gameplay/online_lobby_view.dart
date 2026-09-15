import 'package:kelime_analiz_mobile/domain/analysis/models/word_definition.dart';
import 'package:kelime_analiz_mobile/domain/analysis/repositories/word_definition_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_invite.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/gameplay_tile_models.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/game_result_view.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_actions.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_board.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_draft_feedback.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_match_header.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_rack.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/app_page_route.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

import 'package:kelime_analiz_mobile/domain/gameplay/repositories/online_game_repository.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/game_audio_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_repository.dart';
import 'package:kelime_analiz_mobile/ui/analysis/match_analysis_view.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/services/draft_validation_service.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({
    super.key,
    required this.dictionary,
    required this.audio,
    required this.definitions,
    required this.profile,
    required this.profileService,
    this.initialRoomCode,
    required this.gameService,
  });

  final TrieWordDictionary dictionary;
  final GameAudioRepository audio;
  final WordDefinitionRepository definitions;
  final PlayerProfile profile;
  final PlayerProfileRepository profileService;
  final String? initialRoomCode;
  final OnlineGameRepository gameService;

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  late final OnlineGameRepository _service;
  final _opponentController = TextEditingController();
  String? _roomCode;
  bool _busy = false;
  String? _error;
  String? _notice;
  int _turnDurationSeconds = 86400;
  Stream<OnlineRoom?>? _roomStream;
  late final Stream<List<PlayerInvite>> _invitesStream;
  StreamSubscription<List<PlayerInvite>>? _inviteSoundSubscription;
  final Set<String> _knownInviteRoomCodes = {};
  bool _inviteStreamInitialized = false;

  @override
  void initState() {
    super.initState();
    _service = widget.gameService;
    _invitesStream = widget.profileService
        .invitations(widget.profile.username)
        .asBroadcastStream();

    _inviteSoundSubscription = _invitesStream.listen(
      _handleInvitesForSound,
      onError: (_) {},
    );

    if (widget.initialRoomCode != null) _openRoom(widget.initialRoomCode!);
  }

  void _handleInvitesForSound(List<PlayerInvite> invites) {
    final currentCodes = {for (final invite in invites) invite.roomCode};

    if (!_inviteStreamInitialized) {
      _knownInviteRoomCodes
        ..clear()
        ..addAll(currentCodes);
      _inviteStreamInitialized = true;
      return;
    }

    final hasNewInvite = currentCodes.any(
      (code) => !_knownInviteRoomCodes.contains(code),
    );

    _knownInviteRoomCodes
      ..clear()
      ..addAll(currentCodes);

    if (hasNewInvite) {
      widget.audio.play(GameSound.invite);
    }
  }

  void _openRoom(String code) {
    _roomCode = code;
    _roomStream = _service.room(code);
  }

  @override
  void dispose() {
    _inviteSoundSubscription?.cancel();
    _opponentController.dispose();
    super.dispose();
  }

  Future<void> _challengePlayer() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final room = await _service.createRoom(
        targetUsername: _opponentController.text,
        turnDurationSeconds: _turnDurationSeconds,
      );
      if (mounted) {
        setState(() {
          _opponentController.clear();
          _notice =
              '${room.invitedGuestName ?? 'Arkadaşına'} davet gönderildi, onayı bekleniyor.';
          widget.audio.play(GameSound.uiTap);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = '$error'
              .replaceFirst('Invalid argument(s): ', '')
              .replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinCode(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final room = await _service.joinRoom(code);
      if (!mounted) return;
      setState(() => _openRoom(room.code));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: _roomCode == null
          ? AppBar(title: const Text('Online Maç'))
          : null,
      body: _roomCode == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildLobby(),
              ),
            )
          : _buildRoom(),
    );
  }

  Widget _buildLobby() {
    return ListView(
      children: [
        const Icon(Icons.public_rounded, size: 72, color: Color(0xFF55D6A7)),
        const SizedBox(height: 18),
        const Text(
          'Arkadaşınla oyna',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kullanıcı adını yazarak arkadaşına maç daveti gönder.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        DropdownButtonFormField<int>(
          key: const ValueKey('turn-duration'),
          initialValue: _turnDurationSeconds,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Hamle süresi',
            prefixIcon: Icon(Icons.timer_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            for (final seconds in kTurnDurationOptions)
              DropdownMenuItem(
                value: seconds,
                child: Text(formatTurnDuration(seconds)),
              ),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() => _turnDurationSeconds = value!),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Her oyuncunun sırası geldiğinde bu süre başlar. Diğer maçlarına geçtiğinde süre devam eder.',
          ),
        ),
        TextField(
          controller: _opponentController,
          decoration: const InputDecoration(
            labelText: 'Rakibin kullanıcı adı',
            prefixIcon: Icon(Icons.alternate_email),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _busy ? null : _challengePlayer,
          icon: const Icon(Icons.sports_esports),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('KULLANICIYA DAVET GÖNDER'),
          ),
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<PlayerInvite>>(
          stream: _invitesStream,
          builder: (context, snapshot) {
            final invites = snapshot.data ?? const [];
            if (invites.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gelen davetler',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                for (final invite in invites.take(5))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: Text('${invite.fromUsername} seni davet etti'),
                      subtitle: Text(
                        'Hamle süresi: ${formatTurnDuration(invite.turnDurationSeconds)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _busy ? null : () => _joinCode(invite.roomCode),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_notice != null)
          Card(
            color: const Color(0xFFE0F4EC),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.schedule_send, color: Color(0xFF126B58)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_notice!)),
                ],
              ),
            ),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildRoom() {
    return StreamBuilder<OnlineRoom?>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Oyun açılamadı: ${snapshot.error}'));
        }
        final room = snapshot.data;
        if (room == null) {
          if (snapshot.connectionState == ConnectionState.active) {
            return const Center(
              child: Text('Maç bulunamadı. Oyunlarım listesine dönebilirsin.'),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        if (room.invitedGuestUid == widget.profile.id &&
            room.guestUid == null &&
            !room.isFinished) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${room.hostName} seni oyuna davet etti.',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hamle süresi: ${formatTurnDuration(room.turnDurationSeconds)}',
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : () => _joinCode(room.code),
                  child: const Text('DAVETİ KABUL ET'),
                ),
                if (_error != null) Text(_error!),
              ],
            ),
          );
        }
        if (room.hostUid != widget.profile.id &&
            room.guestUid != widget.profile.id) {
          return const Center(
            child: Text('Bu maça yalnızca kullanıcı davetiyle katılabilirsin.'),
          );
        }
        if (room.guestUid != null && (room.isReady || room.isFinished)) {
          return OnlineMatchView(
            key: ValueKey(room.code),
            room: room,
            service: _service,
            dictionary: widget.dictionary,
            audio: widget.audio,
            definitions: widget.definitions,
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              room.isReady ? Icons.check_circle : Icons.hourglass_top,
              size: 56,
              color: const Color(0xFF55D6A7),
            ),
            const SizedBox(height: 12),
            Text(
              room.isReady ? 'İki oyuncu hazır' : 'Arkadaşın bekleniyor…',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Hamle süresi: ${formatTurnDuration(room.turnDurationSeconds)}',
            ),
            const SizedBox(height: 8),
            Text(
              room.isReady
                  ? 'Online maç bağlantısı kuruldu.'
                  : '${room.invitedGuestName ?? 'Arkadaşına'} davet gönderildi, onayı bekleniyor.',
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('OYUNLARIMA DÖN'),
            ),
          ],
        );
      },
    );
  }
}

class OnlineMatchView extends StatefulWidget {
  const OnlineMatchView({
    super.key,
    required this.room,
    required this.service,
    required this.dictionary,
    required this.audio,
    required this.definitions,
  });

  final OnlineRoom room;
  final OnlineGameRepository service;
  final TrieWordDictionary dictionary;
  final GameAudioRepository audio;
  final WordDefinitionRepository definitions;

  @override
  State<OnlineMatchView> createState() => _OnlineMatchViewState();
}

class _OnlineMatchViewState extends State<OnlineMatchView> {
  final Map<Position, GameplayDraftTile> _draft = {};
  final Set<int> _exchangeSelection = {};
  int? _selectedRackIndex;
  List<int>? _rackOrder;

  // Tahtadaki bir draft taşı sürüklenirken preview hesabından
  // geçici olarak çıkarılır. Böylece taşı kaldırdığın anda
  // kalan kelime yeniden doğrulanır.
  Position? _draggingDraftOrigin;

  bool _busy = false;
  Timer? _timer;
  int? _timeoutAttemptedForTurn;
  DateTime? _timeoutRetryAt;
  late Stream<List<OnlineMove>> _movesStream;
  List<OnlineMove>? _cachedEvents;
  _DerivedOnlineState? _cachedState;
  int? _lastTurnSoundMoveCount;
  bool _lastFinished = false;
  final TransformationController _boardController = TransformationController();

  // Çift tıklamada zoom'un odaklanacağı tahta koordinatı.
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    // Geçmişten açılan bitmiş bir maç sonuç sesi üretmemeli. Bu değer false
    // yalnızca ekran maç devam ederken açıldıysa kalır; böylece canlı bitiş
    // geçişi aşağıdaki sonuç sesini tam bir kez tetikler.
    _lastFinished = widget.room.isFinished;
    // Ekran zaten bizim sıramızdayken açıldıysa eski sıra olayı için ses
    // üretme. Rakip hamlesinden sonra sıra bize geçtiğinde moveCount değişir
    // ve yeni sıra sesi aşağıdaki canlı geçişte bir kez çalar.
    if (widget.room.turnUid == widget.service.currentUid) {
      _lastTurnSoundMoveCount = widget.room.moveCount;
    }
    _movesStream = widget.service.moves(widget.room.code);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _autoPassIfNeeded();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OnlineMatchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.moveCount != widget.room.moveCount ||
        oldWidget.room.status != widget.room.status ||
        oldWidget.room.code != widget.room.code) {
      _clearDraft();
      _timeoutAttemptedForTurn = null;
      _timeoutRetryAt = null;
    }
    if (oldWidget.room.code != widget.room.code) {
      _movesStream = widget.service.moves(widget.room.code);
      _cachedEvents = null;
      _cachedState = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OnlineMove>>(
      stream: _movesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hamleler alınamadı: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final moves = snapshot.data!;

        if (!identical(_cachedEvents, moves)) {
          _cachedState = _deriveState(widget.room, moves);
          _cachedEvents = moves;
        }

        final state = _cachedState!;
        final uid = widget.service.currentUid;
        final isHost = uid == widget.room.hostUid;

        final myRack = isHost ? state.hostRack : state.guestRack;

        final myName = isHost
            ? widget.room.hostName
            : widget.room.guestName ?? 'Sen';

        final rivalName = isHost
            ? widget.room.guestName ?? 'Rakip'
            : widget.room.hostName;

        final myScore = isHost ? state.hostScore : state.guestScore;

        final rivalScore = isHost ? state.guestScore : state.hostScore;

        final synchronized = moves.length == widget.room.moveCount;

        final myTurn =
            widget.room.turnUid == uid &&
            widget.room.isReady &&
            synchronized &&
            !widget.room.isExpired();

        // Sıra gerçekten oynanabilir hale geldiğinde ve yalnızca o hamle
        // numarası için bir kez "sıra sende" sesi çal.
        //
        // Stream'in senkronizasyon sırasında birkaç kez rebuild olması aynı
        // sesi tekrar tekrar tetiklemez.
        if (myTurn &&
            _lastTurnSoundMoveCount != widget.room.moveCount &&
            !widget.room.isFinished) {
          _lastTurnSoundMoveCount = widget.room.moveCount;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.audio.play(GameSound.turn);
            }
          });
        }

        final canDraft =
            widget.room.isReady &&
            synchronized &&
            !widget.room.isFinished &&
            !_busy;

        final remaining = widget.room.remainingSeconds();

        final lastMovePositions = _lastMovePositions(moves);

        // Soru işareti her zaman stream'deki EN SON oynanmış hamleyi takip eder.
        // Böylece ben oynayınca benim hamleme, rakip oynayınca otomatik olarak
        // rakibin yeni hamlesine geçer. Draft sırasında görünmez.
        final latestPlayedMove = _lastPlayedMove(moves);

        final definitionMove =
            latestPlayedMove != null &&
                latestPlayedMove.placements.every(
                  (placement) => state.board.tileAt(placement.position) != null,
                )
            ? latestPlayedMove
            : null;

        final definitionBadgePosition = _definitionBadgePosition(
          definitionMove,
        );

        // Son oynanan hamle kimin oynadığına bakılmadan koyu gösterilir.
        // Ben oynarsam benim son hamlem, rakip oynarsa onun son hamlesi koyu olur.
        final darkenLastMove = lastMovePositions.isNotEmpty;

        final previewDraftEntries = _draft.entries
            .where((entry) => entry.key != _draggingDraftOrigin)
            .toList(growable: false);

        final validation = evaluateDraft(
          board: state.board,
          rack: myRack,
          placements: previewDraftEntries
              .map(
                (entry) => Placement(
                  position: entry.key,
                  letter: entry.value.letter,
                  isBlank: entry.value.isBlank,
                ),
              )
              .toList(),
          dictionary: widget.dictionary,
        );

        final hasPreviewDraft = previewDraftEntries.isNotEmpty;

        final usedRackIndexes = <int>{
          for (final tile in _draft.values) tile.rackIndex,
        };

        final displayOrder =
            _rackOrder != null && _rackOrder!.length == myRack.length
            ? List<int>.from(_rackOrder!)
            : List<int>.generate(myRack.length, (index) => index);

        // Room status finished olduğunda gameplay yerine doğrudan
        // sonuç ekranı gösterilir. Skorlar ve istatistikler aynı move
        // stream'inden üretildiği için iki oyuncuda da aynı sonucu görür.
        if (widget.room.isFinished) {
          final bestMove = _bestMoveForPlayer(moves, uid);

          final endedBy = widget.room.endedBy;
          final finishedByForfeit = endedBy != null;

          // "Maçı Bitir" butonuna basan oyuncu pes etmiş sayılır.
          // Bu nedenle skor önde olsa bile sonucu kayıp olarak gösterir.
          final resultIsDraw = !finishedByForfeit && myScore == rivalScore;

          final resultDidWin = finishedByForfeit
              ? endedBy != uid
              : myScore > rivalScore;

          if (!_lastFinished) {
            _lastFinished = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              widget.audio.play(
                resultIsDraw
                    ? GameSound.uiTap
                    : resultDidWin
                    ? GameSound.win
                    : GameSound.lose,
              );
            });
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF176326),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Color(0xFFF5F7F8),
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: GameResultView(
              myName: myName,
              opponentName: rivalName,
              myScore: myScore,
              opponentScore: rivalScore,
              didWin: resultDidWin,
              isDraw: resultIsDraw,
              finishedByForfeit: finishedByForfeit,
              totalMoves: moves.length,
              durationText: _gameDurationText(widget.room, moves),
              bestMoveWord: bestMove?.word ?? '',
              bestMoveScore: bestMove?.score ?? 0,
              modeLabel: 'Klasik 15×15',
              canAnalyze: state.gameTurns.isNotEmpty,
              busy: _busy,
              onAnalyze: () {
                _showAnalysis(state);
              },
              onRematch: () {
                _requestRematch(rivalName);
              },
              onHome: () {
                Navigator.of(context).pop();
              },
            ),
          );
        }

        _lastFinished = false;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF084D27),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: ColoredBox(
            color: const Color(0xFFF4F7F5),
            child: Column(
              children: [
                GameplayMatchHeader(
                  myName: myName,
                  rivalName: rivalName,
                  myScore: myScore,
                  rivalScore: rivalScore,
                  myTurn: myTurn,
                  remainingSeconds: remaining,
                  bagRemaining: state.bagRemaining,
                  isFinished: widget.room.isFinished,
                  onBack: () => Navigator.of(context).pop(),
                  onExchange:
                      myTurn &&
                          state.bagRemaining > 0 &&
                          !widget.room.isFinished &&
                          !_busy
                      ? () => _chooseAndExchange(myRack, state.bagRemaining)
                      : null,
                  onFinish: !widget.room.isFinished && !_busy
                      ? () => _confirmFinish(state)
                      : null,
                ),

                // Header kompakt kalır; kalan alanı tahta doldurur.
                // Böylece header ile tahta/rack arasında gereksiz boşluk oluşmaz.
                Expanded(
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onDoubleTapDown: (details) {
                            _doubleTapPosition = details.localPosition;
                          },
                          onDoubleTap: _toggleBoardZoom,
                          child: InteractiveViewer(
                            transformationController: _boardController,
                            alignment: Alignment.topLeft,
                            minScale: 1,
                            maxScale: 3.5,
                            panEnabled: true,
                            scaleEnabled: true,
                            constrained: true,

                            // Zoom ve pan yalnızca tahta viewport'u içinde kalır.
                            boundaryMargin: EdgeInsets.zero,
                            clipBehavior: Clip.hardEdge,

                            child: GameplayBoard(
                              board: state.board,
                              draft: _draft,
                              validation: validation,
                              lastMovePositions: lastMovePositions,
                              darkenLastMove: darkenLastMove,
                              definitionBadgePosition: definitionBadgePosition,
                              onDefinitionTap: definitionMove == null
                                  ? null
                                  : () => _showDefinitions(
                                      _formedWords(state.board, definitionMove),
                                    ),
                              draggingDraftOrigin: _draggingDraftOrigin,
                              onDraftDragStarted: _onDraftDragStarted,
                              onDraftDragEnd: _onDraftDragEnd,
                              onCellTap: canDraft
                                  ? (position) =>
                                        _tapBoard(position, state.board, myRack)
                                  : null,
                              onTileDropped: canDraft
                                  ? (position, data) => _dropTile(
                                      position,
                                      data,
                                      state.board,
                                      myRack,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Kelime/puan alanı her zaman aynı yüksekliği kaplar.
                // Aynı zamanda tahtadan alınan draft taşı bu boş alana
                // bırakılırsa rack'e geri döner.
                DragTarget<GameplayTileDragData>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.origin != null,
                  onAcceptWithDetails: (details) {
                    final origin = details.data.origin;
                    if (origin == null) return;

                    setState(() {
                      _draft.remove(origin);
                      _draggingDraftOrigin = null;
                      _selectedRackIndex = null;
                    });
                  },
                  builder: (context, candidates, rejected) {
                    return SizedBox(
                      height: 58,
                      child: hasPreviewDraft
                          ? Center(
                              child: GameplayDraftFeedback(
                                isValid: validation.isValid,
                                message: validation.isValid
                                    ? 'Hamle • '
                                          '${validation.move!.score} puan'
                                    : validation.error ?? 'Kelimeyi tamamla.',
                              ),
                            )
                          : const SizedBox.expand(),
                    );
                  },
                ),

                GameplayRack(
                  rack: myRack,
                  usedRackIndexes: usedRackIndexes,
                  displayOrder: displayOrder,
                  selectedRackIndex: _selectedRackIndex,
                  exchangeSelection: _exchangeSelection,
                  enabled: canDraft,
                  canExchange: myTurn,
                  busy: _busy,
                  onSelect: (index) {
                    widget.audio.play(GameSound.tilePick);
                    setState(() {
                      _selectedRackIndex = index;
                    });
                  },
                  onDragStarted: (_) {
                    widget.audio.play(GameSound.tilePick);
                  },
                  onToggleExchange: (index) {
                    widget.audio.play(GameSound.uiTap);
                    setState(() {
                      _selectedRackIndex = null;

                      if (_exchangeSelection.contains(index)) {
                        _exchangeSelection.remove(index);
                      } else {
                        _exchangeSelection.add(index);
                      }
                    });
                  },
                  onDraftReturned: (origin) {
                    setState(() {
                      _draft.remove(origin);
                      _draggingDraftOrigin = null;
                    });
                    widget.audio.play(GameSound.tileDrop);
                  },
                ),

                GameplayActions(
                  isFinished: widget.room.isFinished,
                  busy: _busy,
                  canPlay: myTurn && validation.isValid,
                  canPass: myTurn,
                  canShuffle: myRack.length - usedRackIndexes.length > 1,
                  canUndo: _draft.isNotEmpty,
                  onPlay: () => _submitDraft(state.board, myRack),
                  onPass: _pass,
                  onShuffle: () => _shuffleRack(myRack),
                  onUndo: _undoDraft,
                  onAnalyze: () => _showAnalysis(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDraftDragStarted(Position origin) {
    if (!_draft.containsKey(origin)) return;
    if (_draggingDraftOrigin == origin) return;

    widget.audio.play(GameSound.tilePick);

    setState(() {
      _draggingDraftOrigin = origin;
    });
  }

  void _onDraftDragEnd(Position origin, bool wasAccepted) {
    if (_draggingDraftOrigin != origin) return;

    setState(() {
      _draggingDraftOrigin = null;
    });
  }

  Future<void> _dropTile(
    Position position,
    GameplayTileDragData data,
    Board board,
    List<String> rack,
  ) async {
    if (board.tileAt(position) != null || _draft.containsKey(position)) return;
    if (data.origin != null) {
      final moved = _draft[data.origin];
      if (moved == null) return;
      setState(() {
        _draft.remove(data.origin);
        _draft[position] = moved;
        _draggingDraftOrigin = null;
      });
      widget.audio.play(GameSound.tileDrop);
      return;
    }
    final rackIndex = data.rackIndex;
    setState(() => _selectedRackIndex = rackIndex);
    await _tapBoard(position, board, rack);
  }

  void _toggleBoardZoom() {
    final zoomed = _boardController.value.getMaxScaleOnAxis() > 1.05;

    if (zoomed) {
      _boardController.value = Matrix4.identity();
      return;
    }

    const scale = 2.2;

    // GestureDetector ve InteractiveViewer aynı board alanını
    // kapladığı için localPosition doğrudan board koordinatıdır.
    final focalPoint = _doubleTapPosition ?? Offset.zero;

    // x' = scale * x + (1 - scale) * focalX
    // y' = scale * y + (1 - scale) * focalY
    //
    // Böylece çift tıklanan nokta zoomdan sonra ekranda
    // aynı yerde kalır; sol üste sabit zoom olmaz.
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, (1 - scale) * focalPoint.dx)
      ..setEntry(1, 3, (1 - scale) * focalPoint.dy);

    _boardController.value = matrix;
  }

  GeneratedMove? _lastPlayedMove(List<OnlineMove> moves) {
    for (final event in moves.reversed) {
      if (event.action == 'play' && event.move != null) {
        return event.move;
      }
    }

    return null;
  }

  Position? _definitionBadgePosition(GeneratedMove? move) {
    if (move == null || move.placements.isEmpty) {
      return null;
    }

    // Hamlede konan gerçek taşlardan birine bağla.
    // Görsel olarak en sağdaki; eşitlikte en üstteki taş seçilir.
    final placements = List<Placement>.from(move.placements)
      ..sort((a, b) {
        final colCompare = b.position.col.compareTo(a.position.col);
        if (colCompare != 0) return colCompare;
        return a.position.row.compareTo(b.position.row);
      });

    return placements.first.position;
  }

  Set<Position> _lastMovePositions(List<OnlineMove> moves) {
    for (final event in moves.reversed) {
      final move = event.move;
      if (event.action != 'play' || move == null) continue;

      return {for (final placement in move.placements) placement.position};
    }

    return const {};
  }

  List<String> _formedWords(Board board, GeneratedMove move) {
    final placed = {for (final item in move.placements) item.position: item};
    String? letterAt(Position position) =>
        placed[position]?.letter ?? board.tileAt(position)?.letter;
    final words = <String>{move.word};
    for (final placement in move.placements) {
      final vertical = move.direction == Direction.horizontal;
      var row = placement.position.row;
      var col = placement.position.col;
      while (true) {
        final previous = Position(
          row - (vertical ? 1 : 0),
          col - (vertical ? 0 : 1),
        );
        if (!_validPosition(previous) || letterAt(previous) == null) break;
        row = previous.row;
        col = previous.col;
      }
      final buffer = StringBuffer();
      var current = Position(row, col);
      while (_validPosition(current) && letterAt(current) != null) {
        buffer.write(letterAt(current));
        current = Position(
          current.row + (vertical ? 1 : 0),
          current.col + (vertical ? 0 : 1),
        );
      }
      if (buffer.length > 1) words.add(buffer.toString());
    }
    return words.toList(growable: false);
  }

  bool _validPosition(Position position) =>
      position.row >= 0 &&
      position.row < 15 &&
      position.col >= 0 &&
      position.col < 15;

  Future<WordDefinition> _lookupDefinitionSafely(String word) async {
    try {
      return await widget.definitions.lookup(word);
    } catch (_) {
      // Tek bir kelimenin isteği hata verirse tüm popup'ı bozma.
      return WordDefinition(word: word, meanings: const []);
    }
  }

  Future<void> _showDefinitions(List<String> words) async {
    final uniqueWords = <String>[];

    for (final word in words) {
      final normalized = word.trim().toUpperCase();
      if (normalized.isEmpty || uniqueWords.contains(normalized)) {
        continue;
      }
      uniqueWords.add(normalized);
    }

    if (uniqueWords.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF4),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Oluşan kelimeler',
                  style: TextStyle(
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
            child: FutureBuilder<List<WordDefinition>>(
              future: Future.wait(uniqueWords.map(_lookupDefinitionSafely)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'Anlamlar şu anda alınamadı.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final definitions = snapshot.data ?? const <WordDefinition>[];

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.52,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: definitions.length,
                    separatorBuilder: (_, _) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final definition = definitions[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            definition.word.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF126B58),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (definition.meanings.isEmpty)
                            const Text(
                              'TDK’da anlam bulunamadı veya bağlantı kurulamadı.',
                              style: TextStyle(
                                color: Color(0xFF5F625E),
                                fontSize: 13,
                              ),
                            )
                          else
                            for (
                              var meaningIndex = 0;
                              meaningIndex < definition.meanings.length;
                              meaningIndex++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  '${meaningIndex + 1}. '
                                  '${definition.meanings[meaningIndex]}',
                                  style: const TextStyle(
                                    color: Color(0xFF343733),
                                    fontSize: 13.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _autoPassIfNeeded() async {
    if (_busy ||
        !widget.room.isReady ||
        !widget.room.isExpired() ||
        (_timeoutRetryAt != null &&
            DateTime.now().isBefore(_timeoutRetryAt!)) ||
        _timeoutAttemptedForTurn == widget.room.moveCount) {
      return;
    }
    final expiringRoom = widget.room;
    _timeoutAttemptedForTurn = expiringRoom.moveCount;
    try {
      await widget.service.expireTurn(expiringRoom);
    } catch (error) {
      _showError(error);
      // Retry on a later tick after a transient connection failure.
      if (mounted) {
        _timeoutAttemptedForTurn = null;
        _timeoutRetryAt = DateTime.now().add(const Duration(seconds: 15));
      }
    }
  }

  void _clearDraft() {
    _draft.clear();
    _exchangeSelection.clear();
    _selectedRackIndex = null;
    _rackOrder = null;
    _draggingDraftOrigin = null;
  }

  void _shuffleRack(List<String> rack) {
    if (rack.length < 2) return;

    widget.audio.play(GameSound.uiTap);

    final currentOrder = _rackOrder != null && _rackOrder!.length == rack.length
        ? List<int>.from(_rackOrder!)
        : List<int>.generate(rack.length, (index) => index);

    final order = List<int>.from(currentOrder)..shuffle();

    // Çok düşük ihtimalle shuffle aynı sırayı üretirse
    // animasyonun mutlaka görünmesi için bir kez döndür.
    if (_sameRackOrder(order, currentOrder)) {
      final first = order.removeAt(0);
      order.add(first);
    }

    setState(() {
      _rackOrder = order;
      _selectedRackIndex = null;
    });
  }

  bool _sameRackOrder(List<int> first, List<int> second) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }

    return true;
  }

  void _undoDraft() {
    if (_draft.isEmpty) return;

    widget.audio.play(GameSound.uiTap);

    setState(() {
      _draft.clear();
      _exchangeSelection.clear();
      _selectedRackIndex = null;
      _draggingDraftOrigin = null;
    });
  }

  Future<void> _tapBoard(
    Position position,
    Board board,
    List<String> rack,
  ) async {
    if (board.tileAt(position) != null) return;
    if (_draft.containsKey(position)) {
      setState(() => _draft.remove(position));
      widget.audio.play(GameSound.tileDrop);
      return;
    }
    final index = _selectedRackIndex;
    if (index == null ||
        index >= rack.length ||
        _draft.values.any((tile) => tile.rackIndex == index)) {
      return;
    }
    var letter = rack[index];
    var blank = false;
    if (letter == '?') {
      final turn = widget.room.moveCount;
      final chosen = await _chooseBlankLetter();
      if (chosen == null ||
          !mounted ||
          widget.room.moveCount != turn ||
          !widget.room.isReady ||
          widget.room.isExpired()) {
        return;
      }
      letter = chosen;
      blank = true;
    }
    setState(() {
      _exchangeSelection.remove(index);
      _draft[position] = GameplayDraftTile(
        rackIndex: index,
        letter: letter,
        isBlank: blank,
      );
      _selectedRackIndex = null;
    });
    widget.audio.play(GameSound.tileDrop);
  }

  Future<String?> _chooseBlankLetter() => showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Joker hangi harf olsun?'),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final letter in 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ'.split(''))
              ActionChip(
                label: Text(letter),
                onPressed: () => Navigator.pop(context, letter),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submitDraft(Board board, List<String> rack) async {
    final validation = evaluateDraft(
      board: board,
      rack: rack,
      placements: _draft.entries
          .map(
            (entry) => Placement(
              position: entry.key,
              letter: entry.value.letter,
              isBlank: entry.value.isBlank,
            ),
          )
          .toList(),
      dictionary: widget.dictionary,
    );
    if (!validation.isValid) {
      _showError(validation.error ?? 'Önce taşları yerleştir.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.submitMove(widget.room, validation.move!);
      widget.audio.play(GameSound.moveSuccess);
      if (mounted) {
        setState(_clearDraft);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pass({bool timedOut = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.passTurn(widget.room);
      widget.audio.play(GameSound.uiTap);
      if (mounted) {
        setState(_clearDraft);
        if (timedOut) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Süre dolduğu için otomatik pas geçildi.'),
            ),
          );
        }
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exchange(List<String> rack) async {
    final letters = _exchangeSelection.toList()..sort();
    final selected = letters
        .map((index) => rack[index])
        .toList(growable: false);
    setState(() => _busy = true);
    try {
      await widget.service.exchangeTiles(widget.room, selected);
      widget.audio.play(GameSound.uiTap);
      if (mounted) setState(_clearDraft);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseAndExchange(List<String> rack, int bagRemaining) async {
    final selected = Set<int>.from(_exchangeSelection);
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Değiştirilecek harfler'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < rack.length; index++)
                FilterChip(
                  selected: selected.contains(index),
                  label: Text(
                    '${rack[index]}  ${const KelimeRules().pointsFor(rack[index])}',
                  ),
                  onSelected: (value) => setDialogState(() {
                    value ? selected.add(index) : selected.remove(index);
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('VAZGEÇ'),
            ),
            FilledButton(
              onPressed: selected.isEmpty || selected.length > bagRemaining
                  ? null
                  : () => Navigator.pop(context, selected),
              child: const Text('DEĞİŞTİR'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _exchangeSelection
        ..clear()
        ..addAll(result);
    });
    await _exchange(rack);
  }

  Future<void> _confirmFinish(_DerivedOnlineState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maçı bitir?'),
        content: const Text(
          'Maçı bitirirsen pes etmiş sayılacaksın ve skorun önde olsa bile maçı kaybedeceksin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('MAÇI BİTİR'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _finishGame(state);
  }

  Future<void> _finishGame(_DerivedOnlineState state) async {
    setState(() => _busy = true);
    try {
      await widget.service.finishGame(
        widget.room,
        hostScore: state.hostScore,
        guestScore: state.guestScore,
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    widget.audio.play(GameSound.moveError);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  GeneratedMove? _bestMoveForPlayer(List<OnlineMove> moves, String uid) {
    GeneratedMove? best;

    for (final event in moves) {
      if (event.playerUid != uid ||
          event.action != 'play' ||
          event.move == null) {
        continue;
      }

      final move = event.move!;

      if (best == null || move.score > best.score) {
        best = move;
      }
    }

    return best;
  }

  String _gameDurationText(OnlineRoom room, List<OnlineMove> moves) {
    DateTime? startedAt;

    for (final move in moves) {
      if (move.createdAt != null) {
        startedAt = move.createdAt;
        break;
      }
    }

    final endedAt =
        room.updatedAt ?? (moves.isEmpty ? null : moves.last.createdAt);

    if (startedAt == null || endedAt == null) {
      return '—';
    }

    final duration = endedAt.difference(startedAt);

    if (duration.isNegative) {
      return '—';
    }

    if (duration.inMinutes < 1) {
      return '<1 dk';
    }

    if (duration.inHours < 1) {
      return '${duration.inMinutes} dk';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (minutes == 0) {
      return '$hours sa';
    }

    return '$hours sa $minutes dk';
  }

  Future<void> _requestRematch(String rivalName) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await widget.service.createRoom(
        targetUsername: rivalName,
        turnDurationSeconds: widget.room.turnDurationSeconds,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$rivalName kullanıcısına rövanş isteği gönderildi.'),
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showAnalysis(_DerivedOnlineState state) async {
    if (state.gameTurns.isEmpty) {
      _showError('Bu maçta analiz edilecek oynanmış kelime yok.');
      return;
    }
    setState(() => _busy = true);
    try {
      final analyzer = GameAnalyzer(
        positionAnalyzer: PositionAnalyzer(
          moveGenerator: TrieMoveGenerator(dictionary: widget.dictionary),
        ),
      );
      final report = analyzer.analyze(
        initialBoard: state.initialBoard,
        turns: state.gameTurns,
        topMoveCount: 3,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        AppPageRoute<void>(
          builder: (_) => MatchAnalysisScreen(
            initialBoard: state.initialBoard,
            turns: state.gameTurns,
            report: report,
            turnIsMine: state.gameTurnPlayerUids
                .map((playerUid) => playerUid == widget.service.currentUid)
                .toList(growable: false),
            myName: widget.service.currentUid == widget.room.hostUid
                ? widget.room.hostName
                : widget.room.guestName ?? 'Sen',
            opponentName: widget.service.currentUid == widget.room.hostUid
                ? widget.room.guestName ?? 'Rakip'
                : widget.room.hostName,
            definitions: widget.definitions,
          ),
        ),
      );
    } catch (error) {
      _showError(
        state.gameTurns.isEmpty ? 'Analiz edilecek oynanmış hamle yok.' : error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _DerivedOnlineState _deriveState(OnlineRoom room, List<OnlineMove> moves) {
    final bag = TileBag(random: Random(room.seed));
    var hostRack = bag.draw(const KelimeRules().rackSize);
    var guestRack = bag.draw(const KelimeRules().rackSize);
    final bonusRandom = Random(room.seed ^ 0x5f3759df);
    Position bonus;
    do {
      bonus = Position(bonusRandom.nextInt(15), bonusRandom.nextInt(15));
    } while (KelimelikBoard.classic().cellAt(bonus).premium !=
        PremiumType.none);
    var board = KelimelikBoard.classic(bonus25: bonus);
    final initialBoard = board;
    var hostScore = 0;
    var guestScore = 0;
    final gameTurns = <GameTurn>[];
    final gameTurnPlayerUids = <String>[];

    for (final onlineMove in moves) {
      final isHost = onlineMove.playerUid == room.hostUid;
      final rack = List<String>.from(isHost ? hostRack : guestRack);
      if (onlineMove.action == 'play' && onlineMove.move != null) {
        final move = onlineMove.move!;
        gameTurns.add(
          GameTurn(rack: List<String>.from(rack), playedMove: move),
        );
        gameTurnPlayerUids.add(onlineMove.playerUid);
        for (final placement in move.placements) {
          rack.remove(placement.isBlank ? '?' : placement.letter);
        }
        rack.addAll(bag.draw(7 - rack.length));
        if (isHost) {
          hostScore += move.score;
        } else {
          guestScore += move.score;
        }
        board = board.applyMove(move);
      } else if (onlineMove.action == 'exchange') {
        for (final letter in onlineMove.exchangeLetters) {
          rack.remove(letter);
        }
        rack.addAll(bag.exchange(onlineMove.exchangeLetters));
      }
      if (isHost) {
        hostRack = rack;
      } else {
        guestRack = rack;
      }
    }
    return _DerivedOnlineState(
      initialBoard: initialBoard,
      board: board,
      hostRack: hostRack,
      guestRack: guestRack,
      hostScore: hostScore,
      guestScore: guestScore,
      bagRemaining: bag.remaining,
      gameTurns: gameTurns,
      gameTurnPlayerUids: List<String>.unmodifiable(gameTurnPlayerUids),
    );
  }
}

class _DerivedOnlineState {
  const _DerivedOnlineState({
    required this.initialBoard,
    required this.board,
    required this.hostRack,
    required this.guestRack,
    required this.hostScore,
    required this.guestScore,
    required this.bagRemaining,
    required this.gameTurns,
    required this.gameTurnPlayerUids,
  });

  final Board initialBoard;
  final Board board;
  final List<String> hostRack;
  final List<String> guestRack;
  final int hostScore;
  final int guestScore;
  final int bagRemaining;
  final List<GameTurn> gameTurns;
  final List<String> gameTurnPlayerUids;
}
