// test/core/design_tokens_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/design_tokens.dart';

void main() {
  group('AppSpacing', () {
    test('échelle multiples de 4 + extras hairline et huge', () {
      expect(AppSpacing.xxxs, 2);
      expect(AppSpacing.xxs, 4);
      expect(AppSpacing.xs, 8);
      expect(AppSpacing.sm, 12);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
      expect(AppSpacing.huge, 64);
    });
  });

  group('AppBorderRadius', () {
    test('radius v3 resserrés', () {
      expect(AppBorderRadius.sm, 6);
      expect(AppBorderRadius.md, 10);
      expect(AppBorderRadius.lg, 16);
      expect(AppBorderRadius.pill, 999);
    });
  });

  group('AppSizes', () {
    test('touch targets v3', () {
      expect(AppSizes.primaryButtonHeight, 52);
      expect(AppSizes.secondaryButtonHeight, 44);
      expect(AppSizes.iconButtonSize, 44);
      expect(AppSizes.textFieldMinHeight, 48);
      expect(AppSizes.sectionIconCircle, 28);
      expect(AppSizes.heroIconCircle, 56);
    });

    test('hairline border width', () {
      expect(AppSizes.hairlineBorder, 0.5);
      expect(AppSizes.standardBorder, 1.0);
    });
  });
}
