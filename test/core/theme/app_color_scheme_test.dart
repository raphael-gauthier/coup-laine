// test/core/theme/app_color_scheme_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/theme/app_color_scheme.dart';

/// Compute relative luminance per WCAG 2.1 (sRGB).
double _luminance(Color c) {
  double channel(double s) {
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4) as double;
  }
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('appLightColors — Modern Craft v3.1', () {
    test('background, surface, foreground', () {
      expect(appLightColors.background, const Color(0xFFFAF8F3));
      expect(appLightColors.card, const Color(0xFFFFFFFF));
      expect(appLightColors.foreground, const Color(0xFF161A15));
      expect(appLightColors.mutedForeground, const Color(0xFF5F635A));
    });

    test('primary vert forêt + accent (secondary) cuivre AA', () {
      expect(appLightColors.primary, const Color(0xFF1F3A2E));
      expect(appLightColors.primaryForeground, const Color(0xFFFAF8F3));
      expect(appLightColors.secondary, const Color(0xFF8B5A2B));
      expect(appLightColors.secondaryForeground, const Color(0xFFFFFFFF));
    });

    test('borders & destructive', () {
      expect(appLightColors.border, const Color(0xFFD4CEBE));
      expect(appLightColors.destructive, const Color(0xFF9A2B2A));
      expect(appLightColors.destructiveForeground, const Color(0xFFFFFFFF));
    });

    test('brightness light', () {
      expect(appLightColors.brightness, Brightness.light);
    });
  });

  group('appDarkColors v3.1', () {
    test('background, surface, foreground', () {
      expect(appDarkColors.background, const Color(0xFF0F1311));
      expect(appDarkColors.card, const Color(0xFF1A1F1C));
      expect(appDarkColors.foreground, const Color(0xFFEDEAE2));
    });

    test('primary + accent dark', () {
      expect(appDarkColors.primary, const Color(0xFF7FA48F));
      expect(appDarkColors.secondary, const Color(0xFFD4A57A));
    });

    test('brightness dark', () {
      expect(appDarkColors.brightness, Brightness.dark);
    });
  });

  group('WCAG 2.1 AA contrast — light', () {
    test('foreground/background ≥ 4.5:1', () {
      expect(_contrast(appLightColors.foreground, appLightColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('foreground/card ≥ 4.5:1', () {
      expect(_contrast(appLightColors.foreground, appLightColors.card),
          greaterThanOrEqualTo(4.5));
    });

    test('mutedForeground/background ≥ 4.5:1', () {
      expect(
          _contrast(appLightColors.mutedForeground, appLightColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('mutedForeground/card ≥ 4.5:1', () {
      expect(_contrast(appLightColors.mutedForeground, appLightColors.card),
          greaterThanOrEqualTo(4.5));
    });

    test('primaryForeground/primary ≥ 4.5:1', () {
      expect(_contrast(appLightColors.primaryForeground, appLightColors.primary),
          greaterThanOrEqualTo(4.5));
    });

    test('primary/background ≥ 4.5:1', () {
      expect(_contrast(appLightColors.primary, appLightColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('secondary/background ≥ 4.5:1', () {
      expect(_contrast(appLightColors.secondary, appLightColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('secondaryForeground/secondary ≥ 4.5:1', () {
      expect(
          _contrast(
              appLightColors.secondaryForeground, appLightColors.secondary),
          greaterThanOrEqualTo(4.5));
    });

    test('destructiveForeground/destructive ≥ 4.5:1', () {
      expect(
          _contrast(appLightColors.destructiveForeground,
              appLightColors.destructive),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('WCAG 2.1 AA contrast — dark', () {
    test('foreground/background ≥ 4.5:1', () {
      expect(_contrast(appDarkColors.foreground, appDarkColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('mutedForeground/background ≥ 4.5:1', () {
      expect(
          _contrast(appDarkColors.mutedForeground, appDarkColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('primaryForeground/primary ≥ 4.5:1', () {
      expect(_contrast(appDarkColors.primaryForeground, appDarkColors.primary),
          greaterThanOrEqualTo(4.5));
    });

    test('secondaryForeground/secondary ≥ 4.5:1', () {
      expect(
          _contrast(
              appDarkColors.secondaryForeground, appDarkColors.secondary),
          greaterThanOrEqualTo(4.5));
    });

    test('destructiveForeground/destructive ≥ 4.5:1', () {
      expect(
          _contrast(appDarkColors.destructiveForeground,
              appDarkColors.destructive),
          greaterThanOrEqualTo(4.5));
    });
  });
}
