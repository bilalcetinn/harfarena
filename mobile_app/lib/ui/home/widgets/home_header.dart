import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';
import 'package:kelime_analiz_mobile/core/constants/app_assets.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/core/theme/app_dimensions.dart';
import 'package:kelime_analiz_mobile/core/theme/app_text_styles.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_progression.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.username,
    required this.progression,
    required this.onSettings,
    super.key,
  });

  final String username;
  final PlayerProgression progression;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.brandGreenDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: safeTop + 13,
            left: 22,
            right: 22,
            height: 46,
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Ana Sayfa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                _HarfArenaLogo(),
              ],
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 16,
            height: 58,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF07562D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  PlayerAvatar(
                    username: username,
                    radius: 20,
                    backgroundColor: AppColors.tileBackground,
                    foregroundColor: AppColors.brandGreenDark,
                    borderWidth: 0,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySemiBold.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          progression.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _LevelBadge(level: progression.level),
                  const SizedBox(width: 5),
                  _SettingsButton(onPressed: onSettings),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HarfArenaLogo extends StatelessWidget {
  const _HarfArenaLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.coin.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(
        AppAssets.headerLogo,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.coin),
          const SizedBox(width: 3),
          Text(
            '$level',
            style: AppTextStyles.smallMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.brandGreen.withValues(alpha: 0.46),
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.settings_outlined, size: 17),
      ),
    );
  }
}
