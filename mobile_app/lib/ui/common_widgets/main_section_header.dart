import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/core/constants/app_assets.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class MainSectionHeader extends StatelessWidget {
  const MainSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
    super.key,
  });

  static const double height = 210;

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.brandGreenDark,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, safeTop + 13, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (onBack != null) ...[
                    SizedBox.square(
                      dimension: 38,
                      child: IconButton(
                        tooltip: 'Geri',
                        padding: EdgeInsets.zero,
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: onBack == null ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: onBack == null ? 24 : 20,
                        height: onBack == null ? null : 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: onBack == null ? 0.2 : 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const _HarfArenaLogo(),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5,
                          height: 1.28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
