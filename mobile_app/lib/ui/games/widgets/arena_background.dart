import 'package:flutter/material.dart';

class ArenaBackground extends StatelessWidget {
  const ArenaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF4ED), Color(0xFFF7F8F6)],
        ),
      ),
    );
  }
}
