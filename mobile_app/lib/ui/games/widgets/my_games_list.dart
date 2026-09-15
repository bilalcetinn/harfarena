import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';

import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';

/// Each room keeps its own turn and clock while another match is open.
class MyGamesList extends StatelessWidget {
  const MyGamesList({
    super.key,
    required this.rooms,
    required this.currentPlayerId,
    required this.onOpen,
  });

  final List<OnlineRoom> rooms;
  final String currentPlayerId;
  final ValueChanged<OnlineRoom> onOpen;

  @override
  Widget build(BuildContext context) {
    final activeRooms = rooms
        .where((room) => !room.isFinished && room.status != 'cancelled')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Oyunlarım',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
            ),
            if (activeRooms.isNotEmpty)
              Chip(
                label: Text('${activeRooms.length} maç'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const Text(
          'Kelime düelloları ve davet durumları',
          style: TextStyle(color: Color(0xFF707A6F)),
        ),
        const SizedBox(height: 6),
        if (activeRooms.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Devam eden maçın yok. Oyna bölümünden kullanıcı adıyla davet gönderebilirsin.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        for (final room in activeRooms)
          _RoomCard(
            key: ValueKey('game_${room.code}'),
            room: room,
            currentPlayerId: currentPlayerId,
            onTap: () => onOpen(room),
          ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    super.key,
    required this.room,
    required this.currentPlayerId,
    required this.onTap,
  });

  final OnlineRoom room;
  final String currentPlayerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHost = room.hostUid == currentPlayerId;
    final isInvited =
        room.guestUid == null && room.invitedGuestUid == currentPlayerId;
    final myTurn = room.isReady && room.turnUid == currentPlayerId;
    final rival = isHost
        ? room.guestName ?? room.invitedGuestName ?? 'Rakip bekleniyor'
        : room.hostName;
    final status = room.isReady
        ? (myTurn ? 'Sıra sende' : 'Rakibin sırası')
        : isInvited
        ? 'Davet aldın · Katıl'
        : room.invitedGuestUid != null
        ? 'Davet gönderildi'
        : 'Oda hazır · Rakip bekleniyor';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  PlayerAvatar(
                    username: rival,
                    radius: 25,
                    backgroundColor: const Color(0xFFFFDEA4),
                    foregroundColor: const Color(0xFF5D4200),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rival,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '${formatTurnDuration(room.turnDurationSeconds)} / hamle',
                          style: const TextStyle(
                            color: Color(0xFF707A6F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: myTurn || isInvited
                          ? const Color(0xFFA3F5B2)
                          : const Color(0xFFFFDEA4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: myTurn || isInvited
                            ? const Color(0xFF005225)
                            : const Color(0xFF735200),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isInvited
                          ? 'Davetini kabul et ve oyuna başla'
                          : myTurn
                          ? 'Hamleni yapma sırası sende'
                          : 'Rakibinin hamlesini bekliyorsun',
                      style: const TextStyle(
                        color: Color(0xFF404940),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(108, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(isInvited ? 'Kabul Et' : 'Oyuna Git'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
