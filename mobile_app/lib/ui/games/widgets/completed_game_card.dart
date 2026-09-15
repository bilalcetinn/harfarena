import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';

class CompletedGameCard extends StatelessWidget {
  const CompletedGameCard({
    required this.match,
    required this.currentPlayerId,
    required this.currentUsername,
    required this.onAnalyze,
    super.key,
  });

  final MatchHistoryEntry match;
  final String currentPlayerId;
  final String currentUsername;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final isHost =
        match.hostName.toLowerCase() == currentUsername.toLowerCase();

    final rivalName = isHost ? match.guestName : match.hostName;

    final myScore = isHost ? match.hostScore : match.guestScore;

    final rivalScore = isHost ? match.guestScore : match.hostScore;

    final result = match.outcomeFor(
      playerId: currentPlayerId,
      username: currentUsername,
    );

    final date = DateTime.fromMillisecondsSinceEpoch(match.sequence);

    return FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
      borderRadius: 18,
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(username: rivalName, result: result),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rivalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF12231A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '@$rivalName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF738078),
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Maç tamamlandı • ${_relativeDate(date)}',
                      style: const TextStyle(
                        color: Color(0xFF5E6D64),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              _ResultBadge(result: result),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEDF0EE)),
          const SizedBox(height: 9),
          Row(
            children: [
              const Text(
                'Sen',
                style: TextStyle(color: Color(0xFF3E4D45), fontSize: 10),
              ),
              const SizedBox(width: 5),
              Text(
                '$myScore',
                style: TextStyle(
                  color: result == MatchOutcome.loss
                      ? const Color(0xFF22352B)
                      : AppColors.brandGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '-',
                  style: TextStyle(
                    color: Color(0xFF23342B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$rivalScore',
                style: TextStyle(
                  color: result == MatchOutcome.loss
                      ? const Color(0xFFD43F39)
                      : const Color(0xFF24362C),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  rivalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3E4D45),
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onAnalyze,
                icon: const Icon(Icons.emoji_events_outlined, size: 14),
                label: const Text('Sonucu Gör'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  backgroundColor: const Color(0xFFE8F8EC),
                  side: const BorderSide(color: Color(0xFF9FD9AE)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    final difference = today.difference(day).inDays;

    if (difference <= 0) return 'Bugün';
    if (difference == 1) return 'Dün';

    return '$difference gün önce';
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});

  final MatchOutcome result;

  @override
  Widget build(BuildContext context) {
    final (
      String label,
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (result) {
      MatchOutcome.win => (
        'Kazandın',
        const Color(0xFF9CF0B0),
        const Color(0xFF075D2B),
        Icons.check_rounded,
      ),
      MatchOutcome.loss => (
        'Kaybettin',
        const Color(0xFFFFD3D0),
        const Color(0xFFB92E29),
        Icons.close_rounded,
      ),
      MatchOutcome.draw => (
        'Berabere',
        const Color(0xFFFFDEA2),
        const Color(0xFF735000),
        Icons.remove_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, required this.result});

  final String username;
  final MatchOutcome result;

  @override
  Widget build(BuildContext context) {
    final background = switch (result) {
      MatchOutcome.win => const Color(0xFFE8F0FF),
      MatchOutcome.loss => const Color(0xFFFFE3A8),
      MatchOutcome.draw => const Color(0xFFF8DCE0),
    };

    return PlayerAvatar(
      username: username,
      radius: 20,
      backgroundColor: background,
      foregroundColor: const Color(0xFF23352B),
    );
  }
}
