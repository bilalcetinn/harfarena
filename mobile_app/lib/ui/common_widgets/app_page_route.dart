import 'package:flutter/material.dart';

/// Uygulama içindeki tam ekran sayfalar için kısa ve düşük maliyetli geçiş.
///
/// MaterialPageRoute'un platforma göre değişen daha uzun geçişi yerine yalnızca
/// yeni sayfayı hafifçe görünür yapar. [allowSnapshotting] sayesinde Flutter,
/// geçiş sırasında ağır sayfaları her karede yeniden çizmek zorunda kalmaz.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        allowSnapshotting: true,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 120),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.96,
              end: 1,
            ).animate(curvedAnimation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.012),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
}
