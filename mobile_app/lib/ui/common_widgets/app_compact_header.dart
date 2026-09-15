import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class AppCompactHeader extends StatelessWidget {
  const AppCompactHeader({
    required this.title,
    required this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: AppColors.brandGreenDark,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Geri',
              onPressed: onBack,
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}
