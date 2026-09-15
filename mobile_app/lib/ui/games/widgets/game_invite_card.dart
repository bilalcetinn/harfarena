import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';

class GameInviteCard extends StatelessWidget {
  const GameInviteCard({
    required this.room,
    required this.currentPlayerId,
    required this.incoming,
    required this.isBusy,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  final OnlineRoom room;
  final String currentPlayerId;
  final bool incoming;
  final bool isBusy;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final rivalName = incoming
        ? room.hostName
        : room.invitedGuestName ?? 'Rakip';

    return FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InviteAvatar(username: rivalName, incoming: incoming),
              const SizedBox(width: 14),
              Expanded(
                child: _InviteInfo(
                  room: room,
                  rivalName: rivalName,
                  incoming: incoming,
                ),
              ),
              const SizedBox(width: 9),
              if (incoming)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _relativeTime(room.updatedAt),
                    style: const TextStyle(
                      color: Color(0xFF66736C),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                const _WaitingBadge(),
            ],
          ),
          const SizedBox(height: 16),
          if (incoming)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : onPrimary,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        disabledBackgroundColor: AppColors.brandGreen
                            .withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: isBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                      label: const Text(
                        'Kabul Et',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextButton.icon(
                      onPressed: isBusy ? null : onSecondary,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF35453C),
                        backgroundColor: const Color(0xFFF0F1F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text(
                        'Reddet',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 46,
                child: TextButton.icon(
                  onPressed: isBusy ? null : onSecondary,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF445149),
                    backgroundColor: const Color(0xFFF3F4F4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text(
                    'Daveti İptal Et',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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

class _InviteInfo extends StatelessWidget {
  const _InviteInfo({
    required this.room,
    required this.rivalName,
    required this.incoming,
  });

  final OnlineRoom room;
  final String rivalName;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
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
                  color: Color(0xFF102219),
                  fontSize: 17,
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
                  color: Color(0xFF708078),
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
        if (incoming) ...[
          const SizedBox(height: 5),
          Text(
            '$rivalName seni oyuna davet etti',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF23352B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 15,
              color: AppColors.brandGreen,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${_speedLabel(room.turnDurationSeconds)} • '
                '${formatTurnDuration(room.turnDurationSeconds)} • '
                '15×15 Tahta',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF57675E),
                  fontSize: 11,
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
}

class _InviteAvatar extends StatelessWidget {
  const _InviteAvatar({required this.username, required this.incoming});

  final String username;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PlayerAvatar(
          username: username,
          radius: 27,
          backgroundColor: incoming
              ? const Color(0xFFE8F0FF)
              : const Color(0xFFFFE3A8),
          foregroundColor: const Color(0xFF22352A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        if (incoming)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF3B62D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF564000),
                size: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _WaitingBadge extends StatelessWidget {
  const _WaitingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDEA2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF755100)),
          SizedBox(width: 4),
          Text(
            'Yanıt Bekleniyor',
            style: TextStyle(
              color: Color(0xFF755100),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
