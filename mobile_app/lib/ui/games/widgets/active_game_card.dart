import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';

class ActiveGameCard extends StatelessWidget {
  const ActiveGameCard({
    required this.room,
    required this.currentPlayerId,
    required this.movesStream,
    required this.onTap,
    super.key,
  });

  final OnlineRoom room;
  final String currentPlayerId;
  final Stream<List<OnlineMove>> movesStream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHost = room.hostUid == currentPlayerId;
    final rivalName = isHost ? room.guestName ?? 'Rakip' : room.hostName;
    final myTurn = room.turnUid == currentPlayerId;

    return FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(username: rivalName, myTurn: myTurn),
              const SizedBox(width: 14),
              Expanded(
                child: _OpponentInfo(
                  rivalName: rivalName,
                  duration: room.turnDurationSeconds,
                  updatedAt: room.updatedAt,
                ),
              ),
              const SizedBox(width: 10),
              _TurnBadge(myTurn: myTurn),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEDF0EE)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<OnlineMove>>(
                  stream: movesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData) {
                      return _ScoreLine(
                        myScore: null,
                        rivalScore: null,
                        rivalName: rivalName,
                      );
                    }

                    final moves = snapshot.data!;
                    final hostScore = _scoreFor(room.hostUid, moves);
                    final guestScore = room.guestUid == null
                        ? 0
                        : _scoreFor(room.guestUid!, moves);

                    return _ScoreLine(
                      myScore: isHost ? hostScore : guestScore,
                      rivalScore: isHost ? guestScore : hostScore,
                      rivalName: rivalName,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              _OpenGameButton(myTurn: myTurn, onTap: onTap),
            ],
          ),
        ],
      ),
    );
  }

  static int _scoreFor(String playerId, List<OnlineMove> moves) {
    var score = 0;
    for (final move in moves) {
      if (move.playerUid == playerId) {
        score += move.move?.score ?? 0;
      }
    }
    return score;
  }
}

class _OpponentInfo extends StatelessWidget {
  const _OpponentInfo({
    required this.rivalName,
    required this.duration,
    required this.updatedAt,
  });

  final String rivalName;
  final int duration;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final fast = duration > 0 && duration <= 120;

    return Column(
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '@$rivalName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF738078),
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (fast) ...[
              const Icon(
                Icons.bolt_rounded,
                size: 15,
                color: AppColors.brandGreen,
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: Text(
                '${_speedLabel(duration)} • '
                '${formatTurnDuration(duration)} • '
                '${_relativeTime(updatedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5E6D64),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _speedLabel(int seconds) {
    if (seconds == 0) return 'Süresiz';
    if (seconds <= 120) return 'Hızlı';
    if (seconds <= 900) return 'Normal';
    return 'Uzun';
  }

  static String _relativeTime(DateTime? date) {
    if (date == null) return 'Az önce';

    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Az önce';
    if (difference.inHours < 1) return '${difference.inMinutes} dk önce';
    if (difference.inDays < 1) return '${difference.inHours} saat önce';
    if (difference.inDays == 1) return 'Dün';

    return '${difference.inDays} gün önce';
  }
}

class _TurnBadge extends StatelessWidget {
  const _TurnBadge({required this.myTurn});

  final bool myTurn;

  @override
  Widget build(BuildContext context) {
    final background = myTurn
        ? const Color(0xFF98F1AC)
        : const Color(0xFFFFDEA2);
    final foreground = myTurn
        ? const Color(0xFF075E2A)
        : const Color(0xFF6F4D00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            myTurn ? 'Sıra Sende' : 'Rakibin Sırası',
            style: TextStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.myScore,
    required this.rivalScore,
    required this.rivalName,
  });

  final int? myScore;
  final int? rivalScore;
  final String rivalName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Sen',
          style: TextStyle(color: Color(0xFF3E4D45), fontSize: 12.5),
        ),
        const SizedBox(width: 6),
        Text(
          myScore == null ? '—' : '$myScore',
          style: const TextStyle(
            color: AppColors.brandGreen,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            '-',
            style: TextStyle(
              color: Color(0xFF23342B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          rivalScore == null ? '—' : '$rivalScore',
          style: const TextStyle(
            color: Color(0xFF24362C),
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            rivalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF3E4D45), fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _OpenGameButton extends StatelessWidget {
  const _OpenGameButton({required this.myTurn, required this.onTap});

  final bool myTurn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!myTurn) {
      return TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('Tahtaya Bak'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF536158),
          backgroundColor: const Color(0xFFF2F3F3),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandGreen,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Oyuna Git',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, required this.myTurn});

  final String username;
  final bool myTurn;

  @override
  Widget build(BuildContext context) {
    return PlayerAvatar(
      username: username,
      radius: 27,
      backgroundColor: myTurn
          ? const Color(0xFFE8F0FF)
          : const Color(0xFFFFE9B9),
      foregroundColor: const Color(0xFF23352B),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
