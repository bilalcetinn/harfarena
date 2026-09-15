import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/app_page_route.dart';

void main() {
  test(
    'app page route keeps full-screen transitions short and snapshotable',
    () {
      final route = AppPageRoute<void>(builder: (_) => const SizedBox());

      expect(route.transitionDuration, const Duration(milliseconds: 150));
      expect(
        route.reverseTransitionDuration,
        const Duration(milliseconds: 120),
      );
      expect(route.allowSnapshotting, isTrue);
    },
  );
}
