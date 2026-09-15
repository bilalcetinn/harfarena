import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/common_widgets/letter_tile.dart';

/// Oyunlarım / Liderlik / Profil ekranlarında kullanılan hareketli taş zemini.
///
/// Her taş kendi küçük alanında kapalı bir elips üzerinde hareket eder. Bu
/// yüzden animasyon döngüsü bittiğinde konum sıçramaz ve taşlar birbirinin
/// içinden geçmez. Ana Sayfa bu widget'ı kullanmaz; oradaki HARF / ARENA
/// kompozisyonu kendi FloatingLetterBackground'u ile aynen korunur.
class ArenaGlassBackground extends StatefulWidget {
  const ArenaGlassBackground({super.key});

  @override
  State<ArenaGlassBackground> createState() => _ArenaGlassBackgroundState();
}

class _ArenaGlassBackgroundState extends State<ArenaGlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _tiles = <_MovingTileData>[
    _MovingTileData('K', 1, 0.04, 0.10, 42, -0.15, 0.00, 8, 12),
    _MovingTileData('E', 1, 0.25, 0.11, 38, 0.10, 0.19, 9, 10),
    _MovingTileData('L', 1, 0.46, 0.09, 44, -0.08, 0.41, 8, 13),
    _MovingTileData('İ', 1, 0.67, 0.11, 39, 0.12, 0.63, 9, 11),
    _MovingTileData('M', 2, 0.89, 0.10, 43, -0.13, 0.82, 8, 12),

    _MovingTileData('A', 1, 0.12, 0.28, 45, 0.11, 0.12, 8, 12),
    _MovingTileData('R', 1, 0.33, 0.27, 39, -0.12, 0.34, 9, 11),
    _MovingTileData('E', 1, 0.54, 0.29, 43, 0.09, 0.55, 8, 13),
    _MovingTileData('N', 1, 0.75, 0.27, 40, -0.10, 0.76, 9, 10),
    _MovingTileData('A', 1, 0.96, 0.29, 44, 0.13, 0.93, 7, 12),

    _MovingTileData('D', 4, 0.04, 0.47, 40, 0.12, 0.27, 8, 11),
    _MovingTileData('Ü', 3, 0.25, 0.46, 44, -0.11, 0.49, 9, 13),
    _MovingTileData('E', 1, 0.46, 0.48, 38, 0.08, 0.70, 8, 10),
    _MovingTileData('L', 1, 0.67, 0.46, 43, -0.13, 0.88, 9, 12),
    _MovingTileData('L', 1, 0.89, 0.48, 41, 0.10, 0.08, 8, 11),

    _MovingTileData('O', 2, 0.12, 0.66, 43, -0.12, 0.21, 9, 12),
    _MovingTileData('Y', 3, 0.33, 0.65, 39, 0.11, 0.43, 8, 10),
    _MovingTileData('U', 1, 0.54, 0.67, 45, -0.09, 0.65, 9, 13),
    _MovingTileData('N', 1, 0.75, 0.65, 40, 0.12, 0.84, 8, 11),
    _MovingTileData('C', 4, 0.96, 0.67, 42, -0.10, 0.03, 7, 12),

    _MovingTileData('H', 5, 0.04, 0.85, 44, 0.10, 0.16, 8, 12),
    _MovingTileData('A', 1, 0.25, 0.84, 39, -0.13, 0.37, 9, 10),
    _MovingTileData('R', 1, 0.46, 0.86, 42, 0.12, 0.59, 8, 13),
    _MovingTileData('F', 7, 0.67, 0.84, 40, -0.09, 0.80, 9, 11),
    _MovingTileData('S', 2, 0.89, 0.86, 45, 0.11, 0.97, 8, 12),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Yalnızca tam sayı frekanslar kullanılıyor. t=0 ve t=2π aynı
              // konumu verdiği için repeat sırasında gözle görünür sıçrama yok.
              final t = _controller.value * math.pi * 2;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEAF5EE),
                            Color(0xFFF7F9F7),
                            Color(0xFFF1F6F2),
                          ],
                          stops: [0.0, 0.52, 1.0],
                        ),
                      ),
                    ),
                  ),
                  for (final tile in _tiles)
                    _AnimatedBackgroundTile(
                      data: tile,
                      time: t,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AnimatedBackgroundTile extends StatelessWidget {
  const _AnimatedBackgroundTile({
    required this.data,
    required this.time,
    required this.width,
    required this.height,
  });

  final _MovingTileData data;
  final double time;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final phase = time + (data.phase * math.pi * 2);

    // Küçük, kapalı elipsler. Komşu merkezler birbirinden yeterince uzak ve
    // hareket mesafeleri sınırlı olduğu için taşlar üst üste binmiyor.
    final dx = math.sin(phase) * data.travelX;
    final dy = math.cos(phase * 2) * data.travelY;
    final rotation = data.rotation + (math.sin(phase) * 0.028);

    return Positioned(
      left: (width * data.x) - (data.size / 2) + dx,
      top: (height * data.y) - (data.size / 2) + dy,
      child: Opacity(
        opacity: 0.43,
        child: Transform.rotate(
          angle: rotation,
          child: LetterTile(
            letter: data.letter,
            point: data.point,
            size: data.size,
          ),
        ),
      ),
    );
  }
}

class _MovingTileData {
  const _MovingTileData(
    this.letter,
    this.point,
    this.x,
    this.y,
    this.size,
    this.rotation,
    this.phase,
    this.travelX,
    this.travelY,
  );

  final String letter;
  final int point;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final double phase;
  final double travelX;
  final double travelY;
}
