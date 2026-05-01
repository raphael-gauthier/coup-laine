// lib/core/theme/app_themes.dart
//
// Construit FThemeData v3 Modern Craft via le factory FThemeData. On
// reconstruit chaque widget style avec notre palette (cuivre + vert forêt)
// pour éviter que les styles capturés par Forui restent sur la palette
// par défaut.
//
// `buttonColors` swap `secondaryForeground` par `foreground` : Forui's
// outline button utilise `secondaryForeground` comme couleur de label sur
// un fond `card` (blanc). Notre `secondaryForeground` est clair → label
// invisible. Ce swap n'affecte que les boutons.
import 'package:forui/forui.dart';

import 'app_color_scheme.dart';
import 'app_typography.dart';
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
