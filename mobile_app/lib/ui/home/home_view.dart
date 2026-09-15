import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_stats.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_bottom_navigation.dart';

import 'widgets/floating_letter_background.dart';
import 'widgets/home_header.dart';
import 'widgets/new_game_hero_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    required this.username,
    required this.onPlay,
    required this.onSettings,
    required this.onNavigationSelected,
    this.playerStats = const PlayerStats(),
    this.selectedNavigationIndex = 0,
    this.showBottomNavigation = true,
    super.key,
  });

  final String username;
  final PlayerStats playerStats;
  final int selectedNavigationIndex;
  final bool showBottomNavigation;

  final VoidCallback onPlay;
  final VoidCallback onSettings;
  final ValueChanged<int> onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    const headerHeight = 210.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: FloatingLetterBackground()),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: HomeHeader(
                username: username,
                progression: playerStats.progression,
                onSettings: onSettings,
              ),
            ),

            Positioned(
              top: headerHeight + 105,
              left: 24,
              right: 24,
              child: NewGameHeroCard(onPlay: onPlay, onlinePlayerCount: 3420),
            ),
          ],
        ),
        bottomNavigationBar: showBottomNavigation
            ? MainBottomNavigation(
                selectedIndex: selectedNavigationIndex,
                onDestinationSelected: onNavigationSelected,
              )
            : null,
      ),
    );
  }
}
