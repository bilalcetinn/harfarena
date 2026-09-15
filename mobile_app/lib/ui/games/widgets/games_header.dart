import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

class GamesHeader extends StatelessWidget {
  const GamesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainSectionHeader(
      title: 'Oyunlarım',
      subtitle:
          'Aktif maçlarını, davetlerini ve sonuçlarını tek yerden takip et.',
      icon: Icons.sports_esports_rounded,
    );
  }
}
