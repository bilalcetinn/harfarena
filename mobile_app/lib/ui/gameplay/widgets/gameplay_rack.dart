import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

import 'package:kelime_analiz_mobile/domain/gameplay/models/gameplay_tile_models.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_letter_tile.dart';

class GameplayRack extends StatefulWidget {
  const GameplayRack({
    required this.rack,
    required this.usedRackIndexes,
    required this.displayOrder,
    required this.selectedRackIndex,
    required this.exchangeSelection,
    required this.enabled,
    required this.canExchange,
    required this.busy,
    required this.onSelect,
    required this.onDragStarted,
    required this.onToggleExchange,
    required this.onDraftReturned,
    super.key,
  });

  final List<String> rack;
  final Set<int> usedRackIndexes;
  final List<int> displayOrder;
  final int? selectedRackIndex;
  final Set<int> exchangeSelection;

  final bool enabled;
  final bool canExchange;
  final bool busy;

  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDragStarted;
  final ValueChanged<int> onToggleExchange;
  final ValueChanged<Position> onDraftReturned;

  @override
  State<GameplayRack> createState() => _GameplayRackState();
}

class _GameplayRackState extends State<GameplayRack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shuffleController;

  List<int> _previousOrder = const [];

  @override
  void initState() {
    super.initState();

    _previousOrder = List<int>.from(widget.displayOrder);

    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant GameplayRack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isPureReorder(oldWidget.displayOrder, widget.displayOrder)) {
      _previousOrder = List<int>.from(oldWidget.displayOrder);

      _shuffleController.forward(from: 0);
    } else if (!_sameOrder(oldWidget.displayOrder, widget.displayOrder)) {
      _previousOrder = List<int>.from(widget.displayOrder);

      _shuffleController.value = 1;
    }
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<GameplayTileDragData>(
      key: const ValueKey('rack-drop-zone'),
      onWillAcceptWithDetails: (details) =>
          details.data.origin != null && widget.enabled,
      onAcceptWithDetails: (details) {
        final origin = details.data.origin;

        if (origin != null) {
          widget.onDraftReturned(origin);
        }
      },
      builder: (context, candidates, rejected) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: const BoxDecoration(
            // Rack alanı artık sabit renkte.
            // Taşı tahtadan geri sürüklerken yeşile dönmez.
            color: Color(0xFFF4EFE4),
            border: Border(
              top: BorderSide(color: Color(0xFFE2D6BC), width: 1),
              bottom: BorderSide(color: Color(0xFFE2D6BC), width: 1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 5.0;

              // Eski 29 px civarı taşlar yerine,
              // ana menüdeki görsel ağırlığa yakın
              // daha büyük taşlar.
              final tileWidth = ((constraints.maxWidth - (gap * 6) - 28) / 7)
                  .clamp(38.0, 44.0);

              final tileHeight = tileWidth * 1.22;

              final currentVisible = _visibleIndexes(widget.displayOrder);

              final previousVisible = _visibleIndexes(_previousOrder);

              final rackHeight = tileHeight + 18;

              return SizedBox(
                height: rackHeight,
                child: AnimatedBuilder(
                  animation: _shuffleController,
                  builder: (context, child) {
                    final progress = Curves.easeInOutCubic.transform(
                      _shuffleController.value,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final rackIndex in currentVisible)
                          _AnimatedRackTilePosition(
                            rackIndex: rackIndex,
                            currentVisible: currentVisible,
                            previousVisible: previousVisible,
                            width: constraints.maxWidth,
                            tileWidth: tileWidth,
                            tileHeight: tileHeight,
                            gap: gap,
                            progress: progress,
                            child: _RackTile(
                              index: rackIndex,
                              letter: widget.rack[rackIndex],
                              width: tileWidth,
                              height: tileHeight,
                              selected: widget.selectedRackIndex == rackIndex,
                              exchangeSelected: widget.exchangeSelection
                                  .contains(rackIndex),
                              enabled: widget.enabled && !widget.busy,
                              canExchange: widget.canExchange && !widget.busy,
                              onSelect: () => widget.onSelect(rackIndex),
                              onDragStarted: () =>
                                  widget.onDragStarted(rackIndex),
                              onToggleExchange: () =>
                                  widget.onToggleExchange(rackIndex),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<int> _visibleIndexes(List<int> order) {
    return order
        .where(
          (index) =>
              index >= 0 &&
              index < widget.rack.length &&
              !widget.usedRackIndexes.contains(index),
        )
        .toList(growable: false);
  }

  static bool _sameOrder(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) {
        return false;
      }
    }

    return true;
  }

  static bool _isPureReorder(List<int> oldOrder, List<int> newOrder) {
    if (oldOrder.length != newOrder.length) {
      return false;
    }

    if (_sameOrder(oldOrder, newOrder)) {
      return false;
    }

    final oldSorted = List<int>.from(oldOrder)..sort();

    final newSorted = List<int>.from(newOrder)..sort();

    return _sameOrder(oldSorted, newSorted);
  }
}

class _AnimatedRackTilePosition extends StatelessWidget {
  const _AnimatedRackTilePosition({
    required this.rackIndex,
    required this.currentVisible,
    required this.previousVisible,
    required this.width,
    required this.tileWidth,
    required this.tileHeight,
    required this.gap,
    required this.progress,
    required this.child,
  });

  final int rackIndex;
  final List<int> currentVisible;
  final List<int> previousVisible;
  final double width;
  final double tileWidth;
  final double tileHeight;
  final double gap;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final toIndex = currentVisible.indexOf(rackIndex);

    var fromIndex = previousVisible.indexOf(rackIndex);

    if (fromIndex < 0) {
      fromIndex = toIndex;
    }

    final fromStart = _startX(width, previousVisible.length, tileWidth, gap);

    final toStart = _startX(width, currentVisible.length, tileWidth, gap);

    final fromX = fromStart + fromIndex * (tileWidth + gap);

    final toX = toStart + toIndex * (tileWidth + gap);

    final x = fromX + ((toX - fromX) * progress);

    final wave = math.sin(progress * math.pi);

    final direction = rackIndex.isEven ? -1.0 : 1.0;

    final y = 8 + (wave * 7 * direction);

    final rotation = wave * 0.09 * direction;

    final scale = 1 + (wave * 0.05);

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }

  static double _startX(
    double availableWidth,
    int count,
    double tileWidth,
    double gap,
  ) {
    if (count <= 0) {
      return 0;
    }

    final totalWidth = count * tileWidth + math.max(0, count - 1) * gap;

    return math.max(0, (availableWidth - totalWidth) / 2);
  }
}

class _RackTile extends StatelessWidget {
  const _RackTile({
    required this.index,
    required this.letter,
    required this.width,
    required this.height,
    required this.selected,
    required this.exchangeSelected,
    required this.enabled,
    required this.canExchange,
    required this.onSelect,
    required this.onDragStarted,
    required this.onToggleExchange,
  });

  final int index;
  final String letter;
  final double width;
  final double height;
  final bool selected;
  final bool exchangeSelected;
  final bool enabled;
  final bool canExchange;
  final VoidCallback onSelect;
  final VoidCallback onDragStarted;
  final VoidCallback onToggleExchange;

  @override
  Widget build(BuildContext context) {
    final state = exchangeSelected
        ? GameplayLetterTileState.recommended
        : selected
        ? GameplayLetterTileState.selected
        : enabled
        ? GameplayLetterTileState.normal
        : GameplayLetterTileState.disabled;

    final face = GestureDetector(
      onTap: enabled ? onSelect : null,
      onLongPress: canExchange ? onToggleExchange : null,
      child: GameplayLetterTile(
        letter: letter,
        point: const KelimeRules().pointsFor(letter),
        state: state,
        width: width,
        height: height,
      ),
    );

    if (!enabled) {
      return face;
    }

    return Draggable<GameplayTileDragData>(
      key: ValueKey('rack-$index'),
      data: GameplayTileDragData(rackIndex: index),
      feedback: Material(
        color: Colors.transparent,
        child: GameplayLetterTile(
          letter: letter,
          point: const KelimeRules().pointsFor(letter),
          state: GameplayLetterTileState.selected,
          width: width * 1.08,
          height: height * 1.08,
        ),
      ),
      onDragStarted: onDragStarted,
      childWhenDragging: Opacity(opacity: 0.20, child: face),
      child: face,
    );
  }
}
