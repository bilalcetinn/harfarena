import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class GameplayActions extends StatelessWidget {
  const GameplayActions({
    required this.isFinished,
    required this.busy,
    required this.canPlay,
    required this.canPass,
    required this.canShuffle,
    required this.canUndo,
    required this.onPlay,
    required this.onPass,
    required this.onShuffle,
    required this.onUndo,
    required this.onAnalyze,
    super.key,
  });

  final bool isFinished;
  final bool busy;
  final bool canPlay;
  final bool canPass;
  final bool canShuffle;
  final bool canUndo;

  final VoidCallback onPlay;
  final VoidCallback onPass;
  final VoidCallback onShuffle;
  final VoidCallback onUndo;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        4,
        8,
        7 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: isFinished
          ? SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onAnalyze,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text(
                  'MAÇI ANALİZ ET',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.shuffle_rounded,
                    label: 'Karıştır',
                    enabled: canShuffle && !busy,
                    onTap: onShuffle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.undo_rounded,
                    label: 'Geri Al',
                    enabled: canUndo && !busy,
                    onTap: onUndo,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Pas',
                    enabled: canPass && !busy,
                    onTap: onPass,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _PlayButton(
                    enabled: canPlay && !busy,
                    busy: busy,
                    onTap: onPlay,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: const Color(0xFFFFF6DE),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE6D5AA)),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A672D).withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF4B433A)),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF4B433A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          disabledBackgroundColor: const Color(0xFF9DB8A7),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 22),
                  SizedBox(height: 1),
                  Text(
                    'OYNA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
      ),
    );
  }
}
