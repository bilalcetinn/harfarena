import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

enum GameplayMenuAction { exchange, finish }

class GameplayMatchHeader extends StatelessWidget {
  const GameplayMatchHeader({
    required this.myName,
    required this.rivalName,
    required this.myScore,
    required this.rivalScore,
    required this.myTurn,
    required this.remainingSeconds,
    required this.bagRemaining,
    required this.isFinished,
    required this.onBack,
    this.onExchange,
    this.onFinish,
    super.key,
  });

  final String myName;
  final String rivalName;
  final int myScore;
  final int rivalScore;
  final bool myTurn;
  final int? remainingSeconds;
  final int bagRemaining;
  final bool isFinished;
  final VoidCallback onBack;
  final VoidCallback? onExchange;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10, topPadding + 2, 10, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandGreenDark, AppColors.brandGreen],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$rivalName ile Oyun',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<GameplayMenuAction>(
                  enabled: !isFinished,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case GameplayMenuAction.exchange:
                        onExchange?.call();
                      case GameplayMenuAction.finish:
                        onFinish?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: GameplayMenuAction.exchange,
                      enabled: onExchange != null,
                      child: const Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded),
                          SizedBox(width: 10),
                          Text('Harf Değiştir'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: GameplayMenuAction.finish,
                      enabled: onFinish != null,
                      child: const Row(
                        children: [
                          Icon(Icons.flag_outlined),
                          SizedBox(width: 10),
                          Text('Maçı Bitir'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _PlayerCard(
                  username: myName,
                  score: myScore,
                  active: myTurn && !isFinished,
                  alignRight: false,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _PlayerCard(
                  username: rivalName,
                  score: rivalScore,
                  active: !myTurn && !isFinished,
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFinished
                    ? Icons.flag_rounded
                    : myTurn
                    ? Icons.sync_rounded
                    : Icons.hourglass_bottom_rounded,
                color: const Color(0xFFFFE5A3),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                isFinished
                    ? 'Maç tamamlandı'
                    : myTurn
                    ? 'Sıra Sende'
                    : 'Rakibin Sırası',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 15),
              const SizedBox(width: 4),
              Text(
                isFinished ? '--:--' : _clockLabel(remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$bagRemaining taş',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _clockLabel(int? seconds) {
    if (seconds == null) return '∞';

    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}sa ${minutes}dk';
    }

    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.username,
    required this.score,
    required this.active,
    required this.alignRight,
  });

  final String username;
  final int score;
  final bool active;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final avatar = PlayerAvatar(
      username: username,
      radius: 21,
      backgroundColor: alignRight
          ? const Color(0xFFE8F0FF)
          : const Color(0xFFFFE6A6),
      foregroundColor: const Color(0xFF22412E),
    );

    final details = Expanded(
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF213329),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$score',
            style: TextStyle(
              color: active ? AppColors.brandGreen : const Color(0xFF4D5C54),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: active ? const Color(0xFF6BA57B) : Colors.white,
          width: active ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.11),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: alignRight
            ? [details, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), details],
      ),
    );
  }
}
