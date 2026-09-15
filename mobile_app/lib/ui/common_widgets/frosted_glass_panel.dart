import 'package:flutter/material.dart';

/// Oyunlarım / Liderlik / Profil ekranlarında kullanılan scroll-safe
/// buğulu cam yüzeyi.
///
/// Ana Sayfa'daki hero kartının sütlü / yumuşak görünümüne yaklaşır fakat
/// BackdropFilter kullanmaz. Böylece Android'de kaydırma sırasında daha önce
/// görülen siyahlaşma / compositor artefaktı geri gelmez.
///
/// Arka plandaki hareketli taşlar seçilir durumda kalır; ancak güçlü beyaz
/// katman ve yumuşak gradient sayesinde kartın arkasında daha "buğulu" ve
/// bastırılmış görünür.
class FrostedGlassPanel extends StatelessWidget {
  const FrostedGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
    this.backgroundOpacity = 0.76,
    this.borderOpacity = 0.86,
    this.boxShadow = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double backgroundOpacity;
  final double borderOpacity;
  final bool boxShadow;

  @override
  Widget build(BuildContext context) {
    final topOpacity = (backgroundOpacity + 0.12).clamp(0.0, 1.0).toDouble();
    final middleOpacity = (backgroundOpacity + 0.035)
        .clamp(0.0, 1.0)
        .toDouble();
    final bottomOpacity = (backgroundOpacity - 0.055)
        .clamp(0.0, 1.0)
        .toDouble();

    final radius = BorderRadius.circular(borderRadius);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: boxShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.065),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: topOpacity),
                        const Color(0xFFF8FAF9)
                            .withValues(alpha: middleOpacity),
                        const Color(0xFFF2F7F4)
                            .withValues(alpha: bottomOpacity),
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: borderOpacity),
                      width: 1.1,
                    ),
                  ),
                ),
              ),

              // Camın üst tarafındaki yumuşak ışık, Ana Sayfa kartındaki
              // "frost" hissini güçlendiriyor. Backdrop blur olmadığı için
              // scroll sırasında siyah frame üretmiyor.
              Positioned(
                left: -24,
                right: -24,
                top: -42,
                height: 112,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.45),
                        radius: 1.25,
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
