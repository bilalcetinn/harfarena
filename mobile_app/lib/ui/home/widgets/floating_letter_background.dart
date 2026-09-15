import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/common_widgets/letter_tile.dart';

class FloatingLetterBackground extends StatefulWidget {
  const FloatingLetterBackground({super.key});

  @override
  State<FloatingLetterBackground> createState() =>
      _FloatingLetterBackgroundState();
}

class _FloatingLetterBackgroundState extends State<FloatingLetterBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<_FloatingTileData> _tiles = [
    // ─────────────────────────────
    // SOL TARAF — HARF
    // ─────────────────────────────

    _FloatingTileData(
      letter: 'H',
      point: 5,
      x: -0.045,
      y: 0.285,
      size: 55,
      baseRotation: -0.15,
      phase: 0.0,
      moveX: 1,
      moveY: 1,
    ),

    _FloatingTileData(
      letter: 'A',
      point: 1,
      x: -0.025,
      y: 0.475,
      size: 53,
      baseRotation: 0.12,
      phase: 1.20,
      moveX: -1,
      moveY: -1,
    ),

    _FloatingTileData(
      letter: 'R',
      point: 1,
      x: -0.040,
      y: 0.665,
      size: 55,
      baseRotation: -0.11,
      phase: 2.45,
      moveX: 1,
      moveY: -1,
    ),

    _FloatingTileData(
      letter: 'F',
      point: 7,

      // Kartın arkasında kaybolmaması için
      // biraz sola ve yukarı aldık.
      x: -0.015,
      y: 0.805,

      size: 51,
      baseRotation: 0.10,
      phase: 3.65,
      moveX: -1,
      moveY: 1,
    ),
    // ─────────────────────────────
    // SAĞ TARAF — ARENA
    // ─────────────────────────────
    _FloatingTileData(
      letter: 'A',
      point: 1,
      x: 0.875,
      y: 0.265,
      size: 54,
      baseRotation: 0.13,
      phase: 0.65,
      moveX: -1,
      moveY: 1,
    ),

    _FloatingTileData(
      letter: 'R',
      point: 1,
      x: 0.925,
      y: 0.415,
      size: 55,
      baseRotation: -0.13,
      phase: 1.75,
      moveX: 1,
      moveY: -1,
    ),

    _FloatingTileData(
      letter: 'E',
      point: 1,
      x: 0.915,
      y: 0.575,
      size: 53,
      baseRotation: 0.13,
      phase: 2.85,
      moveX: -1,
      moveY: 1,
    ),

    _FloatingTileData(
      letter: 'N',
      point: 1,
      x: 0.925,
      y: 0.725,
      size: 54,
      baseRotation: -0.10,
      phase: 3.95,
      moveX: 1,
      moveY: 1,
    ),

    _FloatingTileData(
      letter: 'A',
      point: 1,
      x: 0.815,
      y: 0.855,
      size: 51,
      baseRotation: 0.11,
      phase: 5.10,
      moveX: -1,
      moveY: -1,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
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
              final time = _controller.value * math.pi * 2;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Hafif yeşilimsi ana zemin
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFEEF7F1),
                            Color(0xFFF7F8F6),
                            Color(0xFFF7F8F6),
                          ],
                          stops: [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // HARF / ARENA taşları
                  for (final tile in _tiles)
                    Positioned(
                      left: constraints.maxWidth * tile.x,
                      top: constraints.maxHeight * tile.y,
                      child: _FloatingTile(data: tile, time: time),
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

class _FloatingTile extends StatelessWidget {
  const _FloatingTile({required this.data, required this.time});

  final _FloatingTileData data;
  final double time;

  @override
  Widget build(BuildContext context) {
    // Farklı fazlar sayesinde bütün taşlar aynı anda
    // aynı yöne hareket etmiyor.
    final verticalWave = math.sin(time + data.phase);

    final horizontalWave = math.sin((time * 2) + data.phase + 0.4);

    final rotationWave = math.sin(time + data.phase + 0.75);

    final x = horizontalWave * 2.2 * data.moveX;
    final y = verticalWave * 5.5 * data.moveY;

    final rotation = data.baseRotation + (rotationWave * 0.018 * data.moveX);

    return Opacity(
      opacity: 0.72,
      child: Transform.translate(
        offset: Offset(x, y),
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

class _FloatingTileData {
  const _FloatingTileData({
    required this.letter,
    required this.point,
    required this.x,
    required this.y,
    required this.size,
    required this.baseRotation,
    required this.phase,
    required this.moveX,
    required this.moveY,
  });

  final String letter;
  final int point;

  final double x;
  final double y;
  final double size;

  final double baseRotation;
  final double phase;

  final double moveX;
  final double moveY;
}
