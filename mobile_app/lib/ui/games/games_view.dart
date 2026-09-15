import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_bottom_navigation.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_active_tab.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_finished_tab.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_header.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_invites_tab.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_tabs.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/new_game_floating_button.dart';

class GamesView extends StatefulWidget {
  const GamesView({
    required this.roomsStream,
    required this.historyStream,
    required this.movesForRoom,
    required this.currentPlayerId,
    required this.currentUsername,
    required this.onAcceptInvite,
    required this.onRejectInvite,
    required this.onCancelInvite,
    required this.onOpenGame,
    required this.onAnalyze,
    required this.onNewGame,
    required this.onNavigationSelected,
    this.showBottomNavigation = true,
    super.key,
  });

  final Stream<List<OnlineRoom>> roomsStream;
  final Stream<List<MatchHistoryEntry>> historyStream;
  final Stream<List<OnlineMove>> Function(String roomCode) movesForRoom;

  final String currentPlayerId;
  final String currentUsername;

  final Future<void> Function(OnlineRoom room) onAcceptInvite;
  final Future<void> Function(OnlineRoom room) onRejectInvite;
  final Future<void> Function(OnlineRoom room) onCancelInvite;

  final ValueChanged<OnlineRoom> onOpenGame;
  final ValueChanged<MatchHistoryEntry> onAnalyze;
  final VoidCallback onNewGame;
  final ValueChanged<int> onNavigationSelected;
  final bool showBottomNavigation;

  @override
  State<GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<GamesView> {
  // 0 = Aktif, 1 = Davetler, 2 = Bitenler
  int _selectedTab = 0;

  String? _busyRoomCode;

  Future<void> _runRoomAction(
    OnlineRoom room,
    Future<void> Function(OnlineRoom room) action,
  ) async {
    if (_busyRoomCode != null) return;

    setState(() {
      _busyRoomCode = room.code;
    });

    try {
      await action(room);
    } catch (error) {
      if (!mounted) return;

      final message = '$error'
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Bad state: ', '');

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _busyRoomCode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.brandGreenDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Arka plan AppBootstrap'ta tek bir instance olarak sürekli çalışır.
            const GamesHeader(),
            Expanded(
              child: StreamBuilder<List<OnlineRoom>>(
                stream: widget.roomsStream,
                builder: (context, roomsSnapshot) {
                  return StreamBuilder<List<MatchHistoryEntry>>(
                    stream: widget.historyStream,
                    builder: (context, historySnapshot) {
                      if (roomsSnapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Oyunların yüklenemedi. Bağlantını kontrol edip tekrar dene.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final rooms = roomsSnapshot.data ?? const <OnlineRoom>[];

                      final history =
                          historySnapshot.data ?? const <MatchHistoryEntry>[];

                      final incomingInvites = rooms.where((room) {
                        return !room.isFinished &&
                            !room.isReady &&
                            room.status == 'waiting' &&
                            room.guestUid == null &&
                            room.invitedGuestUid == widget.currentPlayerId;
                      }).toList();

                      final outgoingInvites = rooms.where((room) {
                        return !room.isFinished &&
                            !room.isReady &&
                            room.status == 'waiting' &&
                            room.guestUid == null &&
                            room.hostUid == widget.currentPlayerId &&
                            room.invitedGuestUid != null;
                      }).toList();

                      final activeGames = rooms.where((room) {
                        return room.isReady && !room.isFinished;
                      }).toList();

                      final inviteCount =
                          incomingInvites.length + outgoingInvites.length;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: GamesTabs(
                              selectedIndex: _selectedTab,
                              activeCount: activeGames.length,
                              inviteCount: inviteCount,
                              finishedCount: history.length,
                              onChanged: (index) {
                                setState(() {
                                  _selectedTab = index;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: switch (_selectedTab) {
                                0 => GamesActiveTab(
                                  key: const ValueKey('active_games'),
                                  rooms: activeGames,
                                  currentPlayerId: widget.currentPlayerId,
                                  movesForRoom: widget.movesForRoom,
                                  onOpen: widget.onOpenGame,
                                ),
                                1 => GamesInvitesTab(
                                  key: const ValueKey('game_invites'),
                                  incomingRooms: incomingInvites,
                                  outgoingRooms: outgoingInvites,
                                  currentPlayerId: widget.currentPlayerId,
                                  busyRoomCode: _busyRoomCode,
                                  onAccept: (room) {
                                    return _runRoomAction(
                                      room,
                                      widget.onAcceptInvite,
                                    );
                                  },
                                  onReject: (room) {
                                    return _runRoomAction(
                                      room,
                                      widget.onRejectInvite,
                                    );
                                  },
                                  onCancel: (room) {
                                    return _runRoomAction(
                                      room,
                                      widget.onCancelInvite,
                                    );
                                  },
                                ),
                                _ => GamesFinishedTab(
                                  key: const ValueKey('finished_games'),
                                  matches: history,
                                  currentPlayerId: widget.currentPlayerId,
                                  currentUsername: widget.currentUsername,
                                  onAnalyze: widget.onAnalyze,
                                  hasError: historySnapshot.hasError,
                                ),
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // YENİ OYUN artık body'nin üstüne floating olarak binmiyor.
        // Bottom navigation'ın üzerinde kendi sabit alanı var; bu sayede
        // biten oyun kartlarıyla hiçbir durumda üst üste gelmiyor.
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xEEF3F7F4),
              padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
              alignment: Alignment.centerRight,
              child: NewGameFloatingButton(onPressed: widget.onNewGame),
            ),
            if (widget.showBottomNavigation)
              MainBottomNavigation(
                selectedIndex: 1,
                onDestinationSelected: widget.onNavigationSelected,
              ),
          ],
        ),
      ),
    );
  }
}
