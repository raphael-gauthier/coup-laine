// lib/core/design_tokens.dart
import 'package:flutter/widgets.dart';

/// Spacing scale en pixels logiques (multiples de 4 + hairline + huge).
abstract final class AppSpacing {
  AppSpacing._();
  static const double hairline = 2.0;
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double huge = 64;
}

/// Border radii (v3 resserrés).
abstract final class AppBorderRadius {
  AppBorderRadius._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double pill = 999;
}

/// Common animation durations (deprecated — voir AppMotion dans motion.dart).
abstract final class AppDuration {
  AppDuration._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
}

abstract final class AppSizes {
  AppSizes._();

  static const double primaryButtonHeight = 52;
  static const double secondaryButtonHeight = 44;
  static const double iconButtonSize = 44;
  static const double textFieldMinHeight = 48;
  static const double sectionIconCircle = 28;
  static const double heroIconCircle = 56;

  static const double hairlineBorder = 0.5;
  static const double standardBorder = 1.0;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 24, 20, 40);
  static const EdgeInsets rootScreenPadding = EdgeInsets.fromLTRB(20, 40, 20, 40);
  static const EdgeInsets heroCardPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 32);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets listTilePadding = EdgeInsets.fromLTRB(16, 14, 16, 14);
  static const double bottomScrollPadding = 80.0;
}
