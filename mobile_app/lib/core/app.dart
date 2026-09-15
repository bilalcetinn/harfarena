import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class KelimeApp extends StatelessWidget {
  const KelimeApp({required this.home, super.key});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HarfArena',
      theme: AppTheme.light,
      home: home,
    );
  }
}
