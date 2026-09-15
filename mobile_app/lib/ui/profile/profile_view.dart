import 'dart:convert';

import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_progression.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_bottom_navigation.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.playerId,
    required this.historyStream,
    required this.onNavigationSelected,
    required this.onEditProfile,
    this.playerStats = const PlayerStats(),
    this.onOpenMatch,
    this.showBottomNavigation = true,
    super.key,
  });

  final String username;
  final String displayName;
  final String? avatarUrl;
  final String playerId;
  final PlayerStats playerStats;
  final Stream<List<MatchHistoryEntry>> historyStream;

  final ValueChanged<int> onNavigationSelected;
  final VoidCallback onEditProfile;
  final bool showBottomNavigation;
  final ValueChanged<MatchHistoryEntry>? onOpenMatch;

  static const _brandDark = AppColors.brandGreenDark;
  static const _brandGreen = AppColors.brandGreen;
  static const _brandSoft = Color(0xFFE9F6ED);

  static const _page = Color(0xFFF5F7F6);
  static const _text = Color(0xFF172019);
  static const _muted = Color(0xFF707873);
  static const _border = Color(0xFFE3E8E4);

  static const _loss = Color(0xFFC94C43);
  static const _lossSoft = Color(0xFFFBE9E7);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _brandDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _page,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<MatchHistoryEntry>>(
          stream: historyStream,
          builder: (context, snapshot) {
            final history = snapshot.data ?? const <MatchHistoryEntry>[];

            final stats = _ProfileStats.fromHistory(
              history: history,
              playerId: playerId,
              username: username,
            );

            return Column(
              children: [
                const MainSectionHeader(
                  title: 'Profil',
                  subtitle: 'İstatistiklerini, başarımlarını ve son oyunlarını incele.',
                  icon: Icons.person_rounded,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _ProfileIdentityCard(
                        username: username,
                        displayName: displayName,
                        avatarUrl: avatarUrl,
                        stats: stats,
                        playerStats: playerStats,
                        onEdit: onEditProfile,
                      ),
                      const SizedBox(height: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            title: 'Başarımlar',
                            trailing: '${stats.unlockedAchievements}/4',
                          ),
                          const SizedBox(height: 9),
                          _AchievementsCard(stats: stats),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            title: 'Son Oyunlar',
                            trailing: history.isEmpty
                                ? null
                                : 'Son ${history.length < 3 ? history.length : 3}',
                          ),
                          const SizedBox(height: 9),
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData)
                            const _RecentGamesLoading()
                          else if (history.isEmpty)
                            const _EmptyRecentGames()
                          else
                            _RecentGamesCard(
                              playerId: playerId,
                              username: username,
                              games: history.take(3).toList(growable: false),
                              onOpenMatch: onOpenMatch,
                            ),
                          const SizedBox(height: 15),
                          Center(
                            child: Text(
                              'HarfArena',
                              style: TextStyle(
                                color: _muted.withValues(alpha: 0.70),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: showBottomNavigation
            ? MainBottomNavigation(
                selectedIndex: 3,
                onDestinationSelected: onNavigationSelected,
              )
            : null,
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.stats,
    required this.playerStats,
    required this.onEdit,
  });

  final String username;
  final String displayName;
  final String? avatarUrl;
  final _ProfileStats stats;
  final PlayerStats playerStats;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cleanUsername = username.trim().isEmpty ? 'oyuncu' : username.trim();
    final cleanName = displayName.trim().isEmpty
        ? cleanUsername
        : displayName.trim();

    final initial = cleanName.substring(0, 1).toUpperCase();

    return FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      borderRadius: 22,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: ProfileView._brandGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ProfileView._brandGreen.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: const Color(0xFFE3F0FA),
                    child: _ProfileAvatarImage(
                      avatarSource: avatarUrl,
                      initial: initial,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -3,
                bottom: 0,
                child: Material(
                  color: ProfileView._brandDark,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    key: const Key('profile_edit_button'),
                    customBorder: const CircleBorder(),
                    onTap: onEdit,
                    child: const SizedBox.square(
                      dimension: 29,
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cleanName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ProfileView._text,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '@$cleanUsername',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ProfileView._muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          _ProgressionBadge(progression: playerStats.progression),
          const SizedBox(height: 15),
          const Divider(height: 1, color: ProfileView._border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  value: '${stats.totalGames}',
                  label: 'Oyun',
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _ProfileStat(value: '${stats.wins}', label: 'Galibiyet'),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _ProfileStat(
                  value: '%${stats.winRate}',
                  label: 'Kazanma',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressionBadge extends StatelessWidget {
  const _ProgressionBadge({required this.progression});

  final PlayerProgression progression;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: ProfileView._brandSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ProfileView._brandGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        '${progression.title} • Seviye ${progression.level}',
        style: const TextStyle(
          color: ProfileView._brandGreen,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({
    required this.avatarSource,
    required this.initial,
  });

  final String? avatarSource;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final source = avatarSource?.trim();
    final fallback = _AvatarInitial(initial: initial);
    if (source == null || source.isEmpty) return fallback;

    if (source.startsWith('data:image/') && source.contains(';base64,')) {
      try {
        final encoded = source.substring(source.indexOf(';base64,') + 8);
        return Image.memory(
          base64Decode(encoded),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: ProfileView._brandDark,
          fontSize: 31,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 35, color: ProfileView._border);
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: ProfileView._brandDark,
            fontSize: 21,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: ProfileView._muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ProfileView._text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: ProfileView._muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({required this.stats});

  final _ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _AchievementData(
        icon: Icons.emoji_events_rounded,
        title: 'İlk Zafer',
        unlocked: stats.wins >= 1,
      ),
      _AchievementData(
        icon: Icons.workspace_premium_rounded,
        title: '5 Galibiyet',
        unlocked: stats.wins >= 5,
      ),
      _AchievementData(
        icon: Icons.casino_rounded,
        title: '10 Maç',
        unlocked: stats.totalGames >= 10,
      ),
      _AchievementData(
        icon: Icons.local_fire_department_rounded,
        title: '3 Seri',
        unlocked: stats.bestWinStreak >= 3,
      ),
    ];

    return FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final achievement in achievements)
            Expanded(child: _AchievementBadge(data: achievement)),
        ],
      ),
    );
  }
}

class _AchievementData {
  const _AchievementData({
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final bool unlocked;
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.data});

  final _AchievementData data;

  @override
  Widget build(BuildContext context) {
    final color = data.unlocked
        ? ProfileView._brandGreen
        : const Color(0xFFB7BEB9);

    final background = data.unlocked
        ? ProfileView._brandSoft
        : const Color(0xFFF1F3F2);

    return Opacity(
      opacity: data.unlocked ? 1 : 0.62,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: color, size: 24),
              ),
              if (data.unlocked)
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: _AchievementCheck(),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: data.unlocked ? ProfileView._text : ProfileView._muted,
              fontSize: 8.7,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCheck extends StatelessWidget {
  const _AchievementCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: ProfileView._brandGreen,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
    );
  }
}

class _RecentGamesCard extends StatelessWidget {
  const _RecentGamesCard({
    required this.playerId,
    required this.username,
    required this.games,
    required this.onOpenMatch,
  });

  final String playerId;
  final String username;
  final List<MatchHistoryEntry> games;
  final ValueChanged<MatchHistoryEntry>? onOpenMatch;

  @override
  Widget build(BuildContext context) {
    return FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: Column(
        children: [
          for (var index = 0; index < games.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 1,
                indent: 13,
                endIndent: 13,
                color: ProfileView._border,
              ),
            _RecentGameTile(
              playerId: playerId,
              username: username,
              game: games[index],
              onTap: onOpenMatch == null
                  ? null
                  : () => onOpenMatch!(games[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentGameTile extends StatelessWidget {
  const _RecentGameTile({
    required this.playerId,
    required this.username,
    required this.game,
    required this.onTap,
  });

  final String playerId;
  final String username;
  final MatchHistoryEntry game;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedUsername = username.toLowerCase();

    final isHost = game.hostName.toLowerCase() == normalizedUsername;

    final opponent = isHost ? game.guestName : game.hostName;

    final myScore = isHost ? game.hostScore : game.guestScore;

    final opponentScore = isHost ? game.guestScore : game.hostScore;

    final outcome = game.outcomeFor(playerId: playerId, username: username);
    final draw = outcome == MatchOutcome.draw;
    final won = outcome == MatchOutcome.win;

    final resultText = draw
        ? 'Berabere'
        : won
        ? 'Galibiyet'
        : 'Mağlubiyet';

    final resultColor = draw
        ? const Color(0xFF52758E)
        : won
        ? ProfileView._brandGreen
        : ProfileView._loss;

    final resultBackground = draw
        ? const Color(0xFFEAF1F5)
        : won
        ? ProfileView._brandSoft
        : ProfileView._lossSoft;

    final opponentInitial = opponent.trim().isEmpty
        ? '?'
        : opponent.trim().substring(0, 1).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FA),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  opponentInitial,
                  style: const TextStyle(
                    color: Color(0xFF41658E),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ProfileView._text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: resultBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        resultText,
                        style: TextStyle(
                          color: resultColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$myScore - $opponentScore',
                    style: const TextStyle(
                      color: ProfileView._text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${game.roomCode}',
                    style: const TextStyle(
                      color: ProfileView._muted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFADB4AF),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentGamesLoading extends StatelessWidget {
  const _RecentGamesLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: FrostedGlassPanel(
        backgroundOpacity: 0.76,
        padding: EdgeInsets.zero,
        borderRadius: 18,
        child: Center(
          child: CircularProgressIndicator(
            color: ProfileView._brandGreen,
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentGames extends StatelessWidget {
  const _EmptyRecentGames();

  @override
  Widget build(BuildContext context) {
    return const FrostedGlassPanel(
      backgroundOpacity: 0.76,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      borderRadius: 18,
      child: Column(
        children: [
          Icon(Icons.extension_rounded, color: Color(0xFF9BA59F), size: 28),
          SizedBox(height: 7),
          Text(
            'Henüz tamamlanmış oyun yok',
            style: TextStyle(
              color: ProfileView._text,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Bitirdiğin maçlar burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ProfileView._muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.bestWinStreak,
  });

  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final int winRate;
  final int bestWinStreak;

  int get unlockedAchievements {
    var count = 0;

    if (wins >= 1) count++;
    if (wins >= 5) count++;
    if (totalGames >= 10) count++;
    if (bestWinStreak >= 3) count++;

    return count;
  }

  factory _ProfileStats.fromHistory({
    required List<MatchHistoryEntry> history,
    required String playerId,
    required String username,
  }) {
    var wins = 0;
    var losses = 0;
    var draws = 0;

    var streak = 0;
    var bestWinStreak = 0;

    final normalizedUsername = username.trim().toLowerCase();

    // history servisi yeniyi başa aldığı için seri hesabında eskiden
    // yeniye doğru ilerliyoruz.
    for (final game in history.reversed) {
      final outcome = game.outcomeFor(
        playerId: playerId,
        username: normalizedUsername,
      );

      if (outcome == MatchOutcome.win) {
        wins++;
        streak++;

        if (streak > bestWinStreak) {
          bestWinStreak = streak;
        }
      } else if (outcome == MatchOutcome.loss) {
        losses++;
        streak = 0;
      } else {
        draws++;
        streak = 0;
      }
    }

    final totalGames = wins + losses + draws;

    final winRate = totalGames == 0 ? 0 : ((wins / totalGames) * 100).round();

    return _ProfileStats(
      totalGames: totalGames,
      wins: wins,
      losses: losses,
      draws: draws,
      winRate: winRate,
      bestWinStreak: bestWinStreak,
    );
  }
}
