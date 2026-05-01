// lib/core/theme/app_color_scheme.dart
//
// Palette « Modern Craft » v3.1 — vert forêt + cuivre, WCAG 2.1 AA.
//
// Cibles WCAG (vérifiées par test) :
// - text normal sur fond  : ≥ 4.5:1
// - text large / UI       : ≥ 3:1
//
// Ratios light (foreground/background usuels) :
// - foreground #161A15 / background #FAF8F3   ≈ 16:1   (AAA)
// - mutedForeground #5F635A / background      ≈ 5.8:1  (AA)
// - primary #1F3A2E / background               ≈ 12:1   (AAA)
// - secondary #8B5A2B / background             ≈ 5.5:1  (AA)
// - primaryForeground #FAF8F3 / primary        ≈ 12:1   (AAA)
// - secondaryForeground #FFFFFF / secondary    ≈ 5.5:1  (AA)
// - destructive #9A2B2A / background           ≈ 7.2:1  (AAA)
// - destructiveForeground #FFFFFF / destructive ≈ 7.5:1 (AAA)
//
// Ratios dark :
// - foreground #EDEAE2 / background #0F1311   ≈ 16:1   (AAA)
// - mutedForeground #A6AAA1 / background       ≈ 8:1    (AAA)
// - primary #7FA48F / background               ≈ 6.7:1  (AA)
// - secondary #D4A57A / background             ≈ 9:1    (AAA)
// - destructive #E0746B / background           ≈ 5.8:1  (AA)
//
// Mapping FColors :
// - card        ↔ surface      (#FFFFFF / #1A1F1C)
// - muted       ↔ surfaceMuted (#F0EBE0 / #222825)
// - secondary   ↔ accent cuivre (#8B5A2B / #D4A57A)
// - destructive ↔ destructive  (#9A2B2A / #E0746B)
//
// Note : `error` = `destructive` (pas de distinction côté Forui).
//
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

final FColors appLightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  background: const Color(0xFFFAF8F3),
  foreground: const Color(0xFF161A15),
  primary: const Color(0xFF1F3A2E),
  primaryForeground: const Color(0xFFFAF8F3),
  secondary: const Color(0xFF8B5A2B),
  secondaryForeground: const Color(0xFFFFFFFF),
  muted: const Color(0xFFF0EBE0),
  mutedForeground: const Color(0xFF5F635A),
  destructive: const Color(0xFF9A2B2A),
  destructiveForeground: const Color(0xFFFFFFFF),
  error: const Color(0xFF9A2B2A),
  errorForeground: const Color(0xFFFFFFFF),
  border: const Color(0xFFD4CEBE),
  barrier: const Color(0x80161A15),
  card: const Color(0xFFFFFFFF),
);

final FColors appDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  background: const Color(0xFF0F1311),
  foreground: const Color(0xFFEDEAE2),
  primary: const Color(0xFF7FA48F),
  primaryForeground: const Color(0xFF0F1311),
  secondary: const Color(0xFFD4A57A),
  secondaryForeground: const Color(0xFF0F1311),
  muted: const Color(0xFF222825),
  mutedForeground: const Color(0xFFA6AAA1),
  destructive: const Color(0xFFE0746B),
  destructiveForeground: const Color(0xFF0F1311),
  error: const Color(0xFFE0746B),
  errorForeground: const Color(0xFF0F1311),
  border: const Color(0xFF3A413D),
  barrier: const Color(0x80EDEAE2),
  card: const Color(0xFF1A1F1C),
);
