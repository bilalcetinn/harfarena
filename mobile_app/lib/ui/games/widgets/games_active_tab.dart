import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/games/widgets/active_game_card.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_empty_state.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_section_header.dart';

class GamesActiveTab extends StatelessWidget {
  const GamesActiveTab({
    required this.rooms,
    required this.currentPlayerId,
    required this.movesForRoom,
    required this.onOpen,
    super.key,
  });

  final List<OnlineRoom> rooms;
  final String currentPlayerId;
  final Stream<List<OnlineMove>> Function(String roomCode) movesForRoom;
  final ValueChanged<OnlineRoom> onOpen;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const GamesEmptyState(
        icon: Icons.sports_esports_outlined,
        title: 'Aktif düellon yok',
        subtitle: 'Bir davet kabul edildiğinde veya eşleşme bulunduğunda aktif oyunların burada görünecek.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const GamesSectionHeader(
          icon: Icons.play_circle_fill_rounded,
          title: 'AKTİF OYUNLAR',
        ),
        const SizedBox(height: 9),
        for (var index = 0; index < rooms.length; index++) ...[
          ActiveGameCard(
            room: rooms[index],
            currentPlayerId: currentPlayerId,
            movesStream: movesForRoom(rooms[index].code),
            onTap: () => onOpen(rooms[index]),
          ),
          if (index != rooms.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
