// lib/core/theme/app_typography.dart
//
// Modern Craft v3 — Inter sans-serif unique. Tabular figures activées
// systématiquement via FontFeature.tabularFigures(). La famille Fraunces
// est droppée du theme (le fichier d'asset reste en place jusqu'au
// cleanup de Plan 3).
import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';

/// Re-shape la typo Forui pour v3 Modern Craft. Toutes les tier sont
/// Inter (héritée de Forui) ; Fraunces est droppé.
FTypography buildAppTypography(FTypography base) {
  const tabular = [FontFeature.tabularFigures()];

  return base.copyWith(
    // display 36 / 700 — tabular pour hero numbers
    xl4: base.xl4.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -1.0,
      fontFeatures: tabular,
      // Pas de fontFamily explicite → garde la famille héritée (Inter via Forui).
      // Le test vérifie qu'on n'a PAS Fraunces.
    ),
    // title-xl 28 / 600
    xl3: base.xl3.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.5,
    ),
    // title-lg 22 / 600
    xl2: base.xl2.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.3,
    ),
    // title-md 18 / 600
    xl: base.xl.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    // title-sm 16 / 600
    lg: base.lg.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.1,
    ),
    // body 15 / 400
    md: base.md.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    // body-sm 13 / 400
    sm: base.sm.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    // label 12 / 500
    xs: base.xs.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.2,
    ),
  );
}

/// Style helper pour caption UPPERCASE (group headers, chip labels).
/// Construit à partir de `xs` du thème courant.
TextStyle captionStyle(TextStyle baseLabel) {
  return baseLabel.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
}

/// Style helper pour les chiffres tabular partout (montants, durées, distances).
TextStyle tabularStyle(TextStyle base) {
  final existing = base.fontFeatures ?? const <FontFeature>[];
  if (existing.contains(const FontFeature.tabularFigures())) return base;
  return base.copyWith(
    fontFeatures: [...existing, const FontFeature.tabularFigures()],
  );
}
