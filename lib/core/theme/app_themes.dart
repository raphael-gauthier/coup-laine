// lib/core/theme/app_themes.dart
import 'package:forui/forui.dart';

import 'app_color_scheme.dart';
import 'app_typography.dart';

final FThemeData appLightTheme = () {
  final base = FThemes.blue.light.touch;
  return base.copyWith(
    colors: appLightColors,
    typography: buildAppTypography(base.typography),
  );
}();

final FThemeData appDarkTheme = () {
  final base = FThemes.blue.dark.touch;
  return base.copyWith(
    colors: appDarkColors,
    typography: buildAppTypography(base.typography),
  );
}();
