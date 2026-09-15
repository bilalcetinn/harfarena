import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';

class GamesTabs extends StatelessWidget {
  const GamesTabs({
    required this.selectedIndex,
    required this.activeCount,
    required this.inviteCount,
    required this.finishedCount,
    required this.onChanged,
    super.key,
  });

  final int selectedIndex;
  final int activeCount;
  final int inviteCount;
  final int finishedCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FrostedGlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: 26,
        backgroundOpacity: 0.76,
        borderOpacity: 0.80,
        boxShadow: false,
        child: Row(
          children: [
            Expanded(
              child: _GamesTabItem(
                title: 'Aktif',
                count: activeCount,
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _GamesTabItem(
                title: 'Davetler',
                count: inviteCount,
                selected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
            ),
            Expanded(
              child: _GamesTabItem(
                title: 'Bitenler',
                count: finishedCount,
                selected: selectedIndex == 2,
                onTap: () => onChanged(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesTabItem extends StatelessWidget {
  const _GamesTabItem({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF5E6762),
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 7),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFF7C94A)
                        : const Color(0xFFE2E5E7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? const Color(0xFF4B3A00)
                          : const Color(0xFF65706A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
