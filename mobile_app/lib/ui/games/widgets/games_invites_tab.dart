import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/games/widgets/game_invite_card.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_empty_state.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_section_header.dart';

class GamesInvitesTab extends StatelessWidget {
  const GamesInvitesTab({
    required this.incomingRooms,
    required this.outgoingRooms,
    required this.currentPlayerId,
    required this.busyRoomCode,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
    super.key,
  });

  final List<OnlineRoom> incomingRooms;
  final List<OnlineRoom> outgoingRooms;
  final String currentPlayerId;
  final String? busyRoomCode;

  final Future<void> Function(OnlineRoom room) onAccept;
  final Future<void> Function(OnlineRoom room) onReject;
  final Future<void> Function(OnlineRoom room) onCancel;

  @override
  Widget build(BuildContext context) {
    if (incomingRooms.isEmpty && outgoingRooms.isEmpty) {
      return const GamesEmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'Bekleyen davet yok',
        subtitle: 'Yeni bir davet geldiğinde veya gönderdiğin davet yanıt beklediğinde burada göreceksin.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        if (incomingRooms.isNotEmpty) ...[
          const GamesSectionHeader(
            icon: Icons.mail_outline_rounded,
            title: 'GELEN DAVETLER',
            trailing: 'Sıra sende',
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < incomingRooms.length; index++) ...[
            GameInviteCard(
              room: incomingRooms[index],
              currentPlayerId: currentPlayerId,
              incoming: true,
              isBusy: busyRoomCode == incomingRooms[index].code,
              onPrimary: () => onAccept(incomingRooms[index]),
              onSecondary: () => onReject(incomingRooms[index]),
            ),
            if (index != incomingRooms.length - 1) const SizedBox(height: 10),
          ],
        ],
        if (incomingRooms.isNotEmpty && outgoingRooms.isNotEmpty)
          const SizedBox(height: 22),
        if (outgoingRooms.isNotEmpty) ...[
          const GamesSectionHeader(
            icon: Icons.outlined_flag_rounded,
            title: 'GÖNDERİLEN DAVETLER',
            trailing: 'Geri dönüş bekleniyor',
            iconColor: Color(0xFFC69200),
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < outgoingRooms.length; index++) ...[
            GameInviteCard(
              room: outgoingRooms[index],
              currentPlayerId: currentPlayerId,
              incoming: false,
              isBusy: busyRoomCode == outgoingRooms[index].code,
              onPrimary: () {},
              onSecondary: () => onCancel(outgoingRooms[index]),
            ),
            if (index != outgoingRooms.length - 1) const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
