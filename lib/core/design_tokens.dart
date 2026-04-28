// lib/core/design_tokens.dart
import 'package:flutter/widgets.dart';

/// Spacing scale in logical pixels (multiples of 4).
abstract final class AppSpacing {
  AppSpacing._();
  static const double hairline = 2.0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radii used across components.
abstract final class AppBorderRadius {
  AppBorderRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 24;
  static const double pill = 999;
}

/// Common animation durations.
abstract final class AppDuration {
  AppDuration._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 240);
}

/// Concrete element sizes that recur across screens.
abstract final class AppSizes {
  AppSizes._();
  static const double primaryButtonHeight = 56;
  static const double secondaryButtonHeight = 48;
  static const double iconButtonSize = 44;
  static const double textFieldMinHeight = 56;
  static const double sectionIconCircle = 32;
  static const double heroIconCircle = 72;

  /// Standard outer screen padding (used inside FScaffold child for sub-pages
  /// that already have an `FHeader.nested` above).
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 24, 20, 40);

  /// Padding for root screens that don't have an FHeader (the bottom-nav
  /// destinations: Clients, Tournées, Paramètres). The page title is the
  /// first thing rendered, so it needs more breathing room from the status
  /// bar.
  static const EdgeInsets rootScreenPadding = EdgeInsets.fromLTRB(20, 40, 20, 40);

  /// Hero card padding (more generous vertically).
  static const EdgeInsets heroCardPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 32);

  /// Standard FCard padding (used by AppSectionCard).
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// AppListTile internal padding.
  static const EdgeInsets listTilePadding = EdgeInsets.all(16);

  /// Clearance for scrollable lists so the last item clears the bottom nav bar.
  static const double bottomScrollPadding = 80.0;
}
