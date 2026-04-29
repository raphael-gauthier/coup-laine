// lib/core/theme/app_themes.dart
import 'package:forui/forui.dart';

import 'app_color_scheme.dart';
import 'app_typography.dart';

// Build the themes via the FThemeData factory (not FThemes.blue + copyWith)
// so that every widget style — FButton, FAB-via-Material, dialogs, etc. —
// is constructed with our sage/terracotta palette. copyWith(colors:) only
// swaps the .colors field; widget styles capture their colors at build time
// and would have stayed blue.
final FThemeData appLightTheme = () {
  final base = FThemes.blue.light.touch;
  return FThemeData(
    colors: appLightColors,
    touch: true,
    typography: buildAppTypography(base.typography),
  );
}();

final FThemeData appDarkTheme = () {
  final base = FThemes.blue.dark.touch;
  return FThemeData(
    colors: appDarkColors,
    touch: true,
    typography: buildAppTypography(base.typography),
  );
}();
