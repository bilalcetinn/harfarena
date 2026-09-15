import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class GamesSectionHeader extends StatelessWidget {
  const GamesSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor = AppColors.brandGreen,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1C2A22),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (trailing != null)
          Flexible(
            child: Text(
              trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF55635B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
