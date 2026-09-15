import 'package:flutter/material.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

import 'package:kelime_analiz_mobile/domain/gameplay/services/draft_validation_service.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/gameplay_tile_models.dart';
import 'package:kelime_analiz_mobile/ui/gameplay/widgets/gameplay_letter_tile.dart';

class GameplayBoard extends StatelessWidget {
  const GameplayBoard({
    required this.board,
    required this.draft,
    required this.validation,
    required this.lastMovePositions,
    required this.darkenLastMove,
    this.definitionBadgePosition,
    this.onDefinitionTap,
    this.draggingDraftOrigin,
    this.onDraftDragStarted,
    this.onDraftDragEnd,
    this.onCellTap,
    this.onTileDropped,
    super.key,
  });

  final Board board;
  final Map<Position, GameplayDraftTile> draft;
  final DraftValidation validation;
  final Set<Position> lastMovePositions;
  final bool darkenLastMove;

  /// Son oynanmış hamlede anlam butonunun iliştirileceği gerçek tahta taşı.
  final Position? definitionBadgePosition;
  final VoidCallback? onDefinitionTap;

  /// Sürüklenen draft taşının eski hücrede tekrar çizilmesini engeller.
  final Position? draggingDraftOrigin;

  final ValueChanged<Position>? onDraftDragStarted;

  final void Function(Position position, bool wasAccepted)? onDraftDragEnd;

  final ValueChanged<Position>? onCellTap;

  final void Function(Position position, GameplayTileDragData data)?
  onTileDropped;

  static const double gridGap = 1.35;
  static const double cellRadius = 5.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - (gridGap * 14)) / 15;
        final cellHeight = (constraints.maxHeight - (gridGap * 14)) / 15;

        final childAspectRatio = cellHeight <= 0 ? 1.0 : cellWidth / cellHeight;

        const definitionBadgeSize = 11.5;
        final badgePosition = definitionBadgePosition;

        double? definitionBadgeLeft;
        double? definitionBadgeTop;

        if (badgePosition != null) {
          final tileRight =
              badgePosition.col * (cellWidth + gridGap) + cellWidth;
          final tileTop = badgePosition.row * (cellHeight + gridGap);

          // Küçük rozet taşın sağ-üst köşesine ilişir.
          // Yaklaşık üçte biri taşın dışına çıkar; harfi kapatmaz.
          definitionBadgeLeft = (tileRight - definitionBadgeSize * 0.72)
              .clamp(0.0, constraints.maxWidth - definitionBadgeSize)
              .toDouble();

          definitionBadgeTop = (tileTop - definitionBadgeSize * 0.22)
              .clamp(0.0, constraints.maxHeight - definitionBadgeSize)
              .toDouble();
        }

        return Container(
          color: const Color(0xFFC8B27F),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              GridView.builder(
                padding: EdgeInsets.zero,
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 15,
                  childAspectRatio: childAspectRatio,
                  mainAxisSpacing: gridGap,
                  crossAxisSpacing: gridGap,
                ),
                itemCount: 225,
                itemBuilder: (context, index) {
                  final position = Position(index ~/ 15, index % 15);
                  final premium = board.cellAt(position).premium;
                  final isCenter = position.row == 7 && position.col == 7;

                  final tile = board.tileAt(position);

                  // Aktif Draggable widget'ını sürükleme sırasında
                  // tree'den çıkarmıyoruz. Görsel gizlemeyi Draggable'ın
                  // childWhenDragging'i yapıyor. Böylece onDragEnd kesin
                  // çalışıp taşın eski hücresine geri dönmesini sağlayabiliyor.
                  final draftTile = draft[position];

                  final isOpponentLastTile =
                      darkenLastMove &&
                      tile != null &&
                      lastMovePositions.contains(position);

                  return DragTarget<GameplayTileDragData>(
                    onWillAcceptWithDetails: (_) =>
                        tile == null &&
                        draftTile == null &&
                        onTileDropped != null,
                    onAcceptWithDetails: (details) {
                      onTileDropped?.call(position, details.data);
                    },
                    builder: (context, candidates, rejected) {
                      final highlighted = candidates.isNotEmpty;

                      final shouldOutline =
                          validation.wordPositions.contains(position) &&
                          (draftTile != null || tile != null);

                      final outlineColor = validation.isValid
                          ? const Color(0xFF009447)
                          : const Color(0xFFF04438);

                      return InkWell(
                        borderRadius: BorderRadius.circular(cellRadius),
                        onTap: onCellTap == null
                            ? null
                            : () => onCellTap!(position),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          key: ValueKey('cell-${position.row}-${position.col}'),
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cellRadius),
                            color: highlighted
                                ? const Color(0xFFD8EDDE)
                                : _premiumColor(premium, isCenter: isCenter),
                            border: premium == PremiumType.bonus25
                                ? Border.all(
                                    color: const Color(0xFF9A5A00),
                                    width: 1.15,
                                  )
                                : isCenter
                                ? Border.all(
                                    color: const Color(0xFF9B761B),
                                    width: 1.0,
                                  )
                                : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (shouldOutline)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: outlineColor,
                                        borderRadius: BorderRadius.circular(
                                          cellRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (draftTile != null)
                                Padding(
                                  padding: EdgeInsets.all(
                                    shouldOutline ? 1.9 : 0,
                                  ),
                                  child: _DraftBoardTile(
                                    tile: draftTile,
                                    onTileDropped: onTileDropped,
                                    position: position,
                                    onDragStarted: onDraftDragStarted,
                                    onDragEnd: onDraftDragEnd,
                                  ),
                                )
                              else if (tile != null)
                                Padding(
                                  padding: EdgeInsets.all(
                                    shouldOutline ? 1.9 : 0,
                                  ),
                                  child: _CellFittedTile(
                                    letter: tile.letter,
                                    point: tile.isBlank
                                        ? 0
                                        : const KelimeRules().pointsFor(
                                            tile.letter,
                                          ),
                                    state: GameplayLetterTileState.placed,
                                    dark: isOpponentLastTile,
                                  ),
                                )
                              else
                                Center(
                                  child: _PremiumCellLabel(
                                    premium: premium,
                                    isCenter: isCenter,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // OYNA ile kaydedilmiş hamlenin anlam butonu tahta katmanında çizilir.
              // Küçük rozet taşın sağ-üst köşesine hafif taşmış şekilde oturur.
              if (badgePosition != null &&
                  onDefinitionTap != null &&
                  definitionBadgeLeft != null &&
                  definitionBadgeTop != null)
                Positioned(
                  left: definitionBadgeLeft,
                  top: definitionBadgeTop,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDefinitionTap,
                    child: Container(
                      width: definitionBadgeSize,
                      height: definitionBadgeSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF20B85A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 2,
                            offset: const Offset(0, 0.8),
                          ),
                        ],
                      ),
                      child: const Text(
                        '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Color _premiumColor(PremiumType premium, {required bool isCenter}) {
    // İlk hamlenin geçmesi gereken merkez hücresi premium tipinden bağımsız
    // olarak iki yıldızlı, sıcak altın renkte gösterilir. Oyun kuralı engine
    // tarafında zaten merkezin kullanılmasını zorunlu tutuyor.
    if (isCenter) return const Color(0xFFF3D77A);

    return switch (premium) {
      PremiumType.doubleLetter => const Color(0xFFDCEFE3),
      PremiumType.tripleLetter => const Color(0xFF86BC98),
      PremiumType.doubleWord => const Color(0xFFC5DFAE),
      PremiumType.tripleWord => const Color(0xFF4A9363),

      // +25 artık diğer premium hücrelerden ilk bakışta ayrılan güçlü amber.
      PremiumType.bonus25 => const Color(0xFFF2A93B),

      // Boş hücre, ahşap taşlardan belirgin şekilde farklı.
      PremiumType.none => const Color(0xFFE7E9E3),
    };
  }

  static Color _premiumTextColor(PremiumType premium) {
    return switch (premium) {
      PremiumType.doubleLetter => const Color(0xFF2E6240),
      PremiumType.tripleLetter => const Color(0xFF164A2C),
      PremiumType.doubleWord => const Color(0xFF365E25),
      PremiumType.tripleWord => Colors.white,
      PremiumType.bonus25 => const Color(0xFF365A1F),
      PremiumType.none => Colors.transparent,
    };
  }

  static String _premiumLabel(PremiumType premium) {
    return switch (premium) {
      PremiumType.doubleLetter => 'H2',
      PremiumType.tripleLetter => 'H3',
      PremiumType.doubleWord => 'K2',
      PremiumType.tripleWord => 'K3',
      PremiumType.bonus25 => '25',
      PremiumType.none => '',
    };
  }
}

class _PremiumCellLabel extends StatelessWidget {
  const _PremiumCellLabel({required this.premium, required this.isCenter});

  final PremiumType premium;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '★★',
          maxLines: 1,
          style: TextStyle(
            color: Color(0xFF6B5000),
            fontSize: 8.2,
            height: 1,
            letterSpacing: -0.7,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (premium == PremiumType.bonus25) {
      return const FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '★★★',
              maxLines: 1,
              style: TextStyle(
                color: Color(0xFF6B3900),
                fontSize: 5.2,
                height: 0.92,
                letterSpacing: -0.65,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '25',
              maxLines: 1,
              style: TextStyle(
                color: Color(0xFF5A3100),
                fontSize: 7.4,
                height: 0.95,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      GameplayBoard._premiumLabel(premium),
      style: TextStyle(
        color: GameplayBoard._premiumTextColor(premium),
        fontSize: 7,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

/// Kelime çerçevesini, seçili hücrelerin dışındaki kare bir kutu gibi değil;
/// her taşın rounded şeklinin birleşimi gibi çizer.
///
/// Yan yana / alt alta seçili hücreler arasında bağlantı köprüleri eklenir,
/// sonra tüm rounded rect'ler tek bir Path altında birleştirilir.
/// Böylece 2x2, L, T veya artı şeklindeki kelime birleşimlerinde de
/// dış sınır taşların oval formunu takip eder.
class _DraftBoardTile extends StatelessWidget {
  const _DraftBoardTile({
    required this.tile,
    required this.onTileDropped,
    required this.position,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final GameplayDraftTile tile;

  final void Function(Position position, GameplayTileDragData data)?
  onTileDropped;

  final Position position;

  final ValueChanged<Position>? onDragStarted;

  final void Function(Position position, bool wasAccepted)? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final fitted = _CellFittedTile(
      letter: tile.letter,
      point: tile.isBlank ? 0 : const KelimeRules().pointsFor(tile.letter),
      state: GameplayLetterTileState.normal,
      dark: false,
    );

    if (onTileDropped == null) {
      return fitted;
    }

    return Draggable<GameplayTileDragData>(
      key: ValueKey('draft-${position.row}-${position.col}-${tile.rackIndex}'),
      data: GameplayTileDragData(rackIndex: tile.rackIndex, origin: position),

      // Taş gerçekten sürüklemeye alındığı anda:
      // - origin hücre görsel olarak boşalır
      // - live validation/puan hesabından geçici olarak çıkar
      onDragStarted: () {
        onDragStarted?.call(position);
      },

      // Drop kabul edilmezse parent draggingDraftOrigin'i temizler.
      // Draft map'teki taş silinmediği için otomatik olarak eski hücresine döner.
      onDragEnd: (details) {
        onDragEnd?.call(position, details.wasAccepted);
      },

      feedback: Material(
        color: Colors.transparent,
        child: GameplayLetterTile(
          letter: tile.letter,
          point: tile.isBlank ? 0 : const KelimeRules().pointsFor(tile.letter),
          state: GameplayLetterTileState.selected,
          width: 42,
          height: 52,
        ),
      ),

      // Sürükleme başladığı anda eski hücre boş görünür.
      childWhenDragging: const SizedBox.shrink(),
      child: fitted,
    );
  }
}

class _CellFittedTile extends StatelessWidget {
  const _CellFittedTile({
    required this.letter,
    required this.point,
    required this.state,
    required this.dark,
  });

  final String letter;
  final int point;
  final GameplayLetterTileState state;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: GameplayLetterTile(
            letter: letter,
            point: point,
            state: state,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            dark: dark,
          ),
        );
      },
    );
  }
}
