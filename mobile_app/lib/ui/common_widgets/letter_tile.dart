import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

enum LetterTileState { normal, selected, placed, recommended, disabled }

class LetterTile extends StatelessWidget {
  const LetterTile({
    required this.letter,
    this.point,
    this.state = LetterTileState.normal,
    this.size = 46,
    this.onTap,
    this.rotation = 0,
    super.key,
  });

  final String letter;
  final int? point;
  final LetterTileState state;
  final double size;
  final VoidCallback? onTap;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.17;
    final depth = size * 0.075;

    return Transform.rotate(
      angle: rotation,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: state == LetterTileState.disabled ? 0.45 : 1,
          child: SizedBox(
            width: size,
            height: size + depth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Taşın alt kalınlığı / ahşap gövdesi.
                Positioned(
                  left: 1,
                  right: 1,
                  top: depth,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD6B46C), Color(0xFFB98D42)],
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: size * 0.12,
                          offset: Offset(0, size * 0.07),
                        ),
                      ],
                    ),
                  ),
                ),

                // Üst yüzey.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: _faceGradient,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: _borderColor,
                        width: _borderWidth,
                      ),
                      boxShadow: _stateShadows(size),
                    ),
                    child: Stack(
                      children: [
                        // Üst parlama.
                        Positioned(
                          top: size * 0.055,
                          left: size * 0.11,
                          right: size * 0.11,
                          child: Container(
                            height: size * 0.035,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),

                        // Çok hafif ahşap çizgisi.
                        Positioned(
                          left: size * 0.14,
                          right: size * 0.18,
                          top: size * 0.27,
                          child: Transform.rotate(
                            angle: -0.08,
                            child: Container(
                              height: 1,
                              color: const Color(0xFFD7B76D)
                                  .withValues(alpha: 0.22),
                            ),
                          ),
                        ),

                        Positioned(
                          left: size * 0.20,
                          right: size * 0.12,
                          top: size * 0.70,
                          child: Transform.rotate(
                            angle: 0.06,
                            child: Container(
                              height: 1,
                              color: const Color(0xFFB88E48)
                                  .withValues(alpha: 0.16),
                            ),
                          ),
                        ),

                        // Ana harf.
                        Center(
                          child: Transform.translate(
                            offset: Offset(0, -size * 0.015),
                            child: Text(
                              letter.toUpperCase(),
                              style: TextStyle(
                                fontSize: size * 0.43,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: _letterColor,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Puan.
                        if (point != null)
                          Positioned(
                            right: size * 0.09,
                            bottom: size * 0.07,
                            child: Text(
                              '$point',
                              style: TextStyle(
                                fontSize: size * 0.16,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: _pointColor,
                              ),
                            ),
                          ),

                        // Seçili durumda hafif iç çerçeve.
                        if (state == LetterTileState.selected ||
                            state == LetterTileState.recommended)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                margin: EdgeInsets.all(size * 0.055),
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
      ),
    );
  }

  LinearGradient get _faceGradient {
    switch (state) {
      case LetterTileState.disabled:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE1DED4), Color(0xFFCFCABF)],
        );

      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3D0), Color(0xFFFFE5A8), Color(0xFFF5CE7F)],
          stops: [0.0, 0.58, 1.0],
        );
    }
  }

  Color get _borderColor {
    switch (state) {
      case LetterTileState.selected:
        return AppColors.brandGreen;

      case LetterTileState.placed:
        return const Color(0xFFC59D4D);

      case LetterTileState.recommended:
        return AppColors.coin;

      case LetterTileState.disabled:
        return const Color(0xFFBDB8AD);

      case LetterTileState.normal:
        return const Color(0xFFDDBB70);
    }
  }

  double get _borderWidth {
    switch (state) {
      case LetterTileState.selected:
      case LetterTileState.recommended:
        return 2;

      default:
        return 1.2;
    }
  }

  Color get _letterColor {
    switch (state) {
      case LetterTileState.selected:
        return AppColors.brandGreenDark;

      case LetterTileState.disabled:
        return const Color(0xFF7A7770);

      default:
        return const Color(0xFF342B1D);
    }
  }

  Color get _pointColor {
    switch (state) {
      case LetterTileState.selected:
        return AppColors.brandGreen;

      case LetterTileState.disabled:
        return const Color(0xFF89857C);

      default:
        return const Color(0xFF5D4A2A);
    }
  }

  Color get _innerHighlightColor {
    switch (state) {
      case LetterTileState.selected:
        return AppColors.brandGreen.withValues(alpha: 0.25);

      case LetterTileState.recommended:
        return AppColors.coin.withValues(alpha: 0.35);

      default:
        return Colors.transparent;
    }
  }

  List<BoxShadow> _stateShadows(double size) {
    switch (state) {
      case LetterTileState.selected:
        return [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.23),
            blurRadius: size * 0.22,
            spreadRadius: 1,
          ),
        ];

      case LetterTileState.recommended:
        return [
          BoxShadow(
            color: AppColors.coin.withValues(alpha: 0.26),
            blurRadius: size * 0.22,
            spreadRadius: 1,
          ),
        ];

      default:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: size * 0.08,
            offset: Offset(0, size * 0.025),
          ),
        ];
    }
  }
}
