import 'dart:ui';

import 'package:flutter/material.dart';

/// HarfArena'nın ortak yarı saydam, buğulu kart yüzeyi.
///
/// İçerik, boşluk ve köşe yarıçapı ekrana göre değişebilir; bulanıklık,
/// ışıklı kenarlık ve yumuşak gölge bütün kartlarda aynı tasarım dilini korur.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
    this.blurSigma = 7,
    this.surfaceColor = const Color(0x14F4FAF6),
    this.borderColor = const Color(0x80FFFFFF),
    this.enableBackdropBlur = false,
    this.shadowBlurRadius = 28,
    this.shadowOffset = const Offset(0, 10),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final Color surfaceColor;
  final Color borderColor;
  final bool enableBackdropBlur;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Padding(padding: padding, child: child),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.065),
              blurRadius: shadowBlurRadius,
              offset: shadowOffset,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: enableBackdropBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: surface,
                )
              : surface,
        ),
      ),
    );
  }
}
