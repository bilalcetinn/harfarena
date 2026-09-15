import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/core/theme/app_dimensions.dart';
import 'package:kelime_analiz_mobile/core/theme/app_text_styles.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/app_glass_card.dart';

import 'animated_word_tiles.dart';

class NewGameHeroCard extends StatelessWidget {
  const NewGameHeroCard({
    required this.onPlay,
    this.onlinePlayerCount,
    super.key,
  });

  final VoidCallback onPlay;
  final int? onlinePlayerCount;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      borderRadius: 30,
      blurSigma: 7,
      surfaceColor: const Color(0x14F4FAF6),
      borderColor: const Color(0x80FFFFFF),
      enableBackdropBlur: true,
      shadowBlurRadius: 28,
      shadowOffset: const Offset(0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnimatedWordTiles(),

          const SizedBox(height: 16),

          Text(
            'Arkadaşınla oyna veya rastgele bir rakiple\n'
            'eşleşip harflerini tahtada konuştur.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.38,
            ),
          ),

          const SizedBox(height: 16),

          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.schedule_rounded, label: 'Süreyi Sen Seç'),
              _InfoChip(
                icon: Icons.grid_view_rounded,
                label: '15×15 Klasik Tahta',
              ),
            ],
          ),

          const SizedBox(height: 22),

          _ArenaButton(onPressed: onPlay),

          if (onlinePlayerCount != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Şu an ${_formatPlayerCount(onlinePlayerCount!)} oyuncu çevrim içi',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatPlayerCount(int value) {
    final text = value.toString();

    if (text.length <= 3) {
      return text;
    }

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppColors.brandGreen),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.smallMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArenaButton extends StatefulWidget {
  const _ArenaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ArenaButton> createState() => _ArenaButtonState();
}

class _ArenaButtonState extends State<_ArenaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16A34A), Color(0xFF0E8A3E), Color(0xFF0A7435)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E8A3E).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onPressed,
            onHighlightChanged: (pressed) {
              setState(() {
                _pressed = pressed;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                  const Text(
                    'ARENAYA GİR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
