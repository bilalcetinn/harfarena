import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/ui/common_widgets/letter_tile.dart';

class AnimatedWordTiles extends StatefulWidget {
  const AnimatedWordTiles({super.key});

  @override
  State<AnimatedWordTiles> createState() => _AnimatedWordTilesState();
}

class _AnimatedWordTilesState extends State<AnimatedWordTiles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const String _firstWord = 'DÜELLOYA';
  static const String _secondWord = 'BAŞLA';

  static const List<int> _firstPoints = [3, 3, 1, 1, 1, 2, 3, 1];

  static const List<int> _secondPoints = [3, 1, 4, 1, 1];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final time = _controller.value * math.pi * 2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWord(
              word: _firstWord,
              points: _firstPoints,
              time: time,
              phaseOffset: 0,
            ),
            const SizedBox(height: 7),
            _buildWord(
              word: _secondWord,
              points: _secondPoints,
              time: time,
              phaseOffset: 2.4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWord({
    required String word,
    required List<int> points,
    required double time,
    required double phaseOffset,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < word.length; index++) ...[
          _AnimatedLetter(
            letter: word[index],
            point: points[index],
            time: time,
            phase: phaseOffset + (index * 0.75),
            direction: index.isEven ? 1 : -1,
          ),
          if (index != word.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _AnimatedLetter extends StatelessWidget {
  const _AnimatedLetter({
    required this.letter,
    required this.point,
    required this.time,
    required this.phase,
    required this.direction,
  });

  final String letter;
  final int point;
  final double time;
  final double phase;
  final double direction;

  @override
  Widget build(BuildContext context) {
    final vertical = math.sin(time + phase);
    final horizontal = math.sin((time * 2) + phase);
    final rotation = math.sin(time + phase + 0.5);

    return Transform.translate(
      offset: Offset(horizontal * 0.7 * direction, vertical * 1.6),
      child: Transform.rotate(
        angle: rotation * 0.012 * direction,
        child: LetterTile(letter: letter, point: point, size: 32),
      ),
    );
  }
}
