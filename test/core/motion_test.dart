// test/core/motion_test.dart
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/motion.dart';

void main() {
  group('AppMotion', () {
    test('durées', () {
      expect(AppMotion.instant, Duration.zero);
      expect(AppMotion.fast, const Duration(milliseconds: 120));
      expect(AppMotion.normal, const Duration(milliseconds: 200));
      expect(AppMotion.emphasized, const Duration(milliseconds: 280));
    });

    test('courbes', () {
      expect(AppMotion.fastCurve, Curves.easeOut);
      expect(AppMotion.normalCurve, Curves.easeOutCubic);
      expect(AppMotion.emphasizedCurve, Curves.easeInOutCubicEmphasized);
    });
  });
}
