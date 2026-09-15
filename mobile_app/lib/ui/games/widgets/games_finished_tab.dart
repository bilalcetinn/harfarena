import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/games/widgets/completed_game_card.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_empty_state.dart';
import 'package:kelime_analiz_mobile/ui/games/widgets/games_section_header.dart';

class GamesFinishedTab extends StatelessWidget {
  const GamesFinishedTab({
    required this.matches,
    required this.currentPlayerId,
    required this.currentUsername,
    required this.onAnalyze,
    required this.hasError,
    super.key,
  });

  final List<MatchHistoryEntry> matches;
  final String currentPlayerId;
  final String currentUsername;
  final ValueChanged<MatchHistoryEntry> onAnalyze;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const GamesEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Maç geçmişi yüklenemedi',
        subtitle: 'Bağlantını kontrol et. Geçmiş maçların bağlantı geldiğinde tekrar yüklenecek.',
      );
    }

    if (matches.isEmpty) {
      return const GamesEmptyState(
        icon: Icons.flag_outlined,
        title: 'Henüz biten maç yok',
        subtitle:
            'Tamamladığın düellolar skorlarıyla birlikte burada arşivlenecek.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const GamesSectionHeader(
          icon: Icons.check_circle_rounded,
          title: 'BİTEN OYUNLAR',
        ),
        const SizedBox(height: 9),
        for (var index = 0; index < matches.length; index++) ...[
          CompletedGameCard(
            match: matches[index],
            currentPlayerId: currentPlayerId,
            currentUsername: currentUsername,
            onAnalyze: () => onAnalyze(matches[index]),
          ),
          if (index != matches.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
