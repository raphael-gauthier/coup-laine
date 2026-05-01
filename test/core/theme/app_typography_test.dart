// test/core/theme/app_typography_test.dart
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:coup_laine/core/theme/app_typography.dart';

void main() {
  group('buildAppTypography — v3 Inter only', () {
    final base = FThemes.blue.light.touch.typography;
    final t = buildAppTypography(base);

    test('xl4 = display 36/700 sans serif', () {
      expect(t.xl4.fontSize, 36);
      expect(t.xl4.fontWeight, FontWeight.w700);
      expect(t.xl4.fontFamily, isNot('Fraunces'));
      expect(t.xl4.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('xl3 = title-xl 28/600', () {
      expect(t.xl3.fontSize, 28);
      expect(t.xl3.fontWeight, FontWeight.w600);
      expect(t.xl3.fontFamily, isNot('Fraunces'));
    });

    test('xl2 = title-lg 22/600', () {
      expect(t.xl2.fontSize, 22);
      expect(t.xl2.fontWeight, FontWeight.w600);
      expect(t.xl2.fontFamily, isNot('Fraunces'));
    });

    test('xl = title-md 18/600', () {
      expect(t.xl.fontSize, 18);
      expect(t.xl.fontWeight, FontWeight.w600);
    });

    test('lg = title-sm 16/600', () {
      expect(t.lg.fontSize, 16);
      expect(t.lg.fontWeight, FontWeight.w600);
    });

    test('md = body 15/400', () {
      expect(t.md.fontSize, 15);
      expect(t.md.fontWeight, FontWeight.w400);
    });

    test('sm = body-sm 13/400', () {
      expect(t.sm.fontSize, 13);
      expect(t.sm.fontWeight, FontWeight.w400);
    });

    test('xs = label 12/500', () {
      expect(t.xs.fontSize, 12);
      expect(t.xs.fontWeight, FontWeight.w500);
    });
  });
}
