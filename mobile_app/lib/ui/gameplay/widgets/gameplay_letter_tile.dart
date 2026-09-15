import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

enum GameplayLetterTileState { normal, selected, placed, recommended, disabled }

class GameplayLetterTile extends StatelessWidget {
  const GameplayLetterTile({
    required this.letter,
    this.point,
    this.state = GameplayLetterTileState.normal,
    this.width = 46,
    this.height,
    this.rotation = 0,
    this.dark = false,
    super.key,
  });

  final String letter;
  final int? point;
  final GameplayLetterTileState state;
  final double width;
  final double? height;
  final double rotation;

  /// Rakibin son hamlesindeki yeni taşları koyu HarfArena tonu ile gösterir.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final tileHeight = height ?? width * 1.16;
    final shortestSide = math.min(width, tileHeight);
    final depth = math.min(width * 0.075, tileHeight * 0.07);
    final faceHeight = tileHeight - depth;
    final radius = shortestSide * 0.16;

    return Transform.rotate(
      angle: rotation,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: state == GameplayLetterTileState.disabled ? 0.45 : 1,
        child: SizedBox(
          width: width,
          height: tileHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: depth,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    gradient: dark
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1E5E37), Color(0xFF0E351E)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFD5B267), Color(0xFFB4873C)],
                          ),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: shortestSide * 0.10,
                        offset: Offset(0, shortestSide * 0.055),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: faceHeight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    gradient: _faceGradient,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: _borderColor,
                      width: _borderWidth,
                    ),
                    boxShadow: _stateShadows(shortestSide),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: faceHeight * 0.055,
                        left: width * 0.10,
                        right: width * 0.10,
                        child: Container(
                          height: math.max(1, faceHeight * 0.035),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: dark ? 0.14 : 0.42,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, -faceHeight * 0.015),
                          child: Text(
                            letter.toUpperCase(),
                            style: TextStyle(
                              fontSize: shortestSide * 0.44,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: _letterColor,
                              shadows: [
                                Shadow(
                                  color: dark
                                      ? Colors.black.withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.55),
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (point != null)
                        Positioned(
                          right: width * 0.075,
                          bottom: faceHeight * 0.06,
                          child: Text(
                            '$point',
                            style: TextStyle(
                              fontSize: shortestSide * 0.16,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: _pointColor,
                            ),
                          ),
                        ),
                      if (!dark &&
                          (state == GameplayLetterTileState.selected ||
                              state == GameplayLetterTileState.recommended))
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              margin: EdgeInsets.all(shortestSide * 0.045),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  radius * 0.75,
                                ),
                                border: Border.all(
                                  color: _innerHighlightColor,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient get _faceGradient {
    if (dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3D8255), Color(0xFF23653C), Color(0xFF144527)],
        stops: [0.0, 0.55, 1.0],
      );
    }

    if (state == GameplayLetterTileState.disabled) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE1DED4), Color(0xFFCFCABF)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF3D0), Color(0xFFFFE5A8), Color(0xFFF5CE7F)],
      stops: [0.0, 0.58, 1.0],
    );
  }

  Color get _borderColor {
    if (dark) return const Color(0xFF0A311B);

    switch (state) {
      case GameplayLetterTileState.selected:
        return AppColors.brandGreen;
      case GameplayLetterTileState.placed:
        return const Color(0xFFC69A45);
      case GameplayLetterTileState.recommended:
        return AppColors.coin;
      case GameplayLetterTileState.disabled:
        return const Color(0xFFBDB8AD);
      case GameplayLetterTileState.normal:
        return const Color(0xFFDDBB70);
    }
  }

  double get _borderWidth {
    if (dark) return 1.2;

    switch (state) {
      case GameplayLetterTileState.selected:
      case GameplayLetterTileState.recommended:
        return 2;
      default:
        return 1;
    }
  }

  Color get _letterColor {
    if (dark) return const Color(0xFFFFF1C8);

    switch (state) {
      case GameplayLetterTileState.selected:
        return AppColors.brandGreenDark;
      case GameplayLetterTileState.disabled:
        return const Color(0xFF7A7770);
      default:
        return const Color(0xFF342B1D);
    }
  }

  Color get _pointColor {
    if (dark) return const Color(0xFFFFD46C);

    switch (state) {
      case GameplayLetterTileState.selected:
        return AppColors.brandGreen;
      case GameplayLetterTileState.disabled:
        return const Color(0xFF89857C);
      default:
        return const Color(0xFF5D4A2A);
    }
  }

  Color get _innerHighlightColor {
    switch (state) {
      case GameplayLetterTileState.selected:
        return AppColors.brandGreen.withValues(alpha: 0.24);
      case GameplayLetterTileState.recommended:
        return AppColors.coin.withValues(alpha: 0.34);
      default:
        return Colors.transparent;
    }
  }

  List<BoxShadow> _stateShadows(double shortestSide) {
    if (dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: shortestSide * 0.08,
          offset: Offset(0, shortestSide * 0.02),
        ),
      ];
    }

    switch (state) {
      case GameplayLetterTileState.selected:
        return [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.20),
            blurRadius: shortestSide * 0.18,
          ),
        ];
      case GameplayLetterTileState.recommended:
        return [
          BoxShadow(
            color: AppColors.coin.withValues(alpha: 0.23),
            blurRadius: shortestSide * 0.18,
          ),
        ];
      default:
        return const [];
    }
  }
}
