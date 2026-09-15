import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/frosted_glass_panel.dart';

class GamesEmptyState extends StatelessWidget {
  const GamesEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: FrostedGlassPanel(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          borderRadius: 24,
          backgroundOpacity: 0.76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F4E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 33, color: AppColors.brandGreen),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF183526),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7D8981),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
