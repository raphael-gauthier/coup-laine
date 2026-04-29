// lib/core/theme/app_themes.dart
import 'package:forui/forui.dart';

import 'app_color_scheme.dart';
import 'app_typography.dart';

// Build the themes via the FThemeData factory (not FThemes.blue + copyWith)
// so that every widget style — FButton, FAB-via-Material, dialogs, etc. —
// is constructed with our sage/terracotta palette. copyWith(colors:) only
// swaps the .colors field; widget styles capture their colors at build time
// and would have stayed blue.
//
// The button styles are built with a tweaked palette where
// `secondaryForeground` is replaced by `foreground`. forui's outline button
// uses `colors.secondaryForeground` as its text color on a `colors.card`
// (white) background — and our terracotta secondaryForeground is white,
// which makes the label invisible. Only the buttons see the swap; the rest
// of the theme keeps white-on-terracotta semantics for AppSectionCard
// icons, FBadge.secondary, etc.
FThemeData _buildTheme(FColors colors, FTypography baseTypography) {
  final typography = buildAppTypography(baseTypography);
  final style = FStyle.inherit(colors: colors, typography: typography, touch: true);
  final buttonColors = colors.copyWith(secondaryForeground: colors.foreground);
  return FThemeData(
    colors: colors,
    touch: true,
    typography: typography,
    buttonStyles: FButtonStyles.inherit(
      colors: buttonColors,
      typography: typography,
      style: style,
      touch: true,
    ),
  );
}

final FThemeData appLightTheme = _buildTheme(
  appLightColors,
  FThemes.blue.light.touch.typography,
);

final FThemeData appDarkTheme = _buildTheme(
  appDarkColors,
  FThemes.blue.dark.touch.typography,
);
