// test/core/theme/app_color_scheme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/theme/app_color_scheme.dart';

void main() {
  group('appLightColors — Modern Craft', () {
    test('background, surface, foreground', () {
      expect(appLightColors.background, const Color(0xFFFAF8F3));
      expect(appLightColors.card, const Color(0xFFFFFFFF));
      expect(appLightColors.foreground, const Color(0xFF1B1F1A));
      expect(appLightColors.mutedForeground, const Color(0xFF6B6F66));
    });

    test('primary vert forêt + accent (secondary) cuivre', () {
      expect(appLightColors.primary, const Color(0xFF1F3A2E));
      expect(appLightColors.primaryForeground, const Color(0xFFFAF8F3));
      expect(appLightColors.secondary, const Color(0xFFB8895C));
      expect(appLightColors.secondaryForeground, const Color(0xFFFAF8F3));
    });

    test('borders & destructive', () {
      expect(appLightColors.border, const Color(0xFFE8E4DA));
      expect(appLightColors.destructive, const Color(0xFFA8403E));
      expect(appLightColors.destructiveForeground, const Color(0xFFFAF8F3));
    });

    test('brightness light', () {
      expect(appLightColors.brightness, Brightness.light);
    });
  });

  group('appDarkColors', () {
    test('background, surface, foreground', () {
      expect(appDarkColors.background, const Color(0xFF0F1311));
      expect(appDarkColors.card, const Color(0xFF1A1F1C));
      expect(appDarkColors.foreground, const Color(0xFFEDEAE2));
    });

    test('primary + accent dark', () {
      expect(appDarkColors.primary, const Color(0xFF7DA08B));
      expect(appDarkColors.secondary, const Color(0xFFD4A47A));
    });

    test('brightness dark', () {
      expect(appDarkColors.brightness, Brightness.dark);
    });
  });
}
