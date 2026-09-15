import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class DurationSection extends StatelessWidget {
  const DurationSection({
    required this.selectedDuration,
    required this.onSelected,
    super.key,
  });

  final int selectedDuration;
  final ValueChanged<int> onSelected;

  static const List<DurationOptionData> _durations = [
    DurationOptionData(seconds: 120, title: '2 dk', subtitle: 'Hızlı'),
    DurationOptionData(seconds: 300, title: '5 dk', subtitle: 'Normal'),
    DurationOptionData(seconds: 900, title: '15 dk', subtitle: 'Rahat'),
    DurationOptionData(seconds: 3600, title: '1 saat', subtitle: 'Uzun'),
    DurationOptionData(seconds: 86400, title: '24 saat', subtitle: 'Günlük'),
    DurationOptionData(seconds: 0, title: 'Süresiz', subtitle: 'Serbest'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hamle Süresi',
          style: TextStyle(
            color: Color(0xFF153725),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Her oyuncunun bir hamle için sahip olacağı süre.',
          style: TextStyle(color: Color(0xFF738078), fontSize: 13),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _durations.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) {
            final option = _durations[index];

            return _DurationTile(
              option: option,
              selected: selectedDuration == option.seconds,
              onTap: () => onSelected(option.seconds),
            );
          },
        ),
      ],
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DurationOptionData option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandGreen
                : Colors.white.withValues(alpha: 0.67),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brandGreen : const Color(0xFFE0E8E2),
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.brandGreen.withValues(alpha: 0.18),
                  blurRadius: 13,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                option.title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1C3B2B),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.subtitle,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.72)
                      : const Color(0xFF89928D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DurationOptionData {
  const DurationOptionData({
    required this.seconds,
    required this.title,
    required this.subtitle,
  });

  final int seconds;
  final String title;
  final String subtitle;
}
