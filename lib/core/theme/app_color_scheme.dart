// lib/core/theme/app_color_scheme.dart
//
// Palette « Modern Craft » v3 — vert forêt + cuivre. Remplace la palette
// « Pastoral Chic » sage/terracotta. Cf. spec §1.1.
//
// Mapping FColors :
// - card        ↔ surface      (#FFFFFF / #1A1F1C)
// - muted       ↔ surfaceMuted (#F2EFE8 / #222825)
// - secondary   ↔ accent cuivre (#B8895C / #D4A47A)
// - destructive ↔ destructive  (#A8403E / #D46B68)
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
  foreground: const Color(0xFF1B1F1A),
  primary: const Color(0xFF1F3A2E),
  primaryForeground: const Color(0xFFFAF8F3),
  secondary: const Color(0xFFB8895C),
  secondaryForeground: const Color(0xFFFAF8F3),
  muted: const Color(0xFFF2EFE8),
  mutedForeground: const Color(0xFF6B6F66),
  destructive: const Color(0xFFA8403E),
  destructiveForeground: const Color(0xFFFAF8F3),
  error: const Color(0xFFA8403E),
  errorForeground: const Color(0xFFFAF8F3),
  border: const Color(0xFFE8E4DA),
  barrier: const Color(0x801B1F1A),
  card: const Color(0xFFFFFFFF),
);

final FColors appDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  background: const Color(0xFF0F1311),
  foreground: const Color(0xFFEDEAE2),
  primary: const Color(0xFF7DA08B),
  primaryForeground: const Color(0xFF0F1311),
  secondary: const Color(0xFFD4A47A),
  secondaryForeground: const Color(0xFF0F1311),
  muted: const Color(0xFF222825),
  mutedForeground: const Color(0xFF9CA09A),
  destructive: const Color(0xFFD46B68),
  destructiveForeground: const Color(0xFF0F1311),
  error: const Color(0xFFD46B68),
  errorForeground: const Color(0xFF0F1311),
  border: const Color(0xFF2A302D),
  barrier: const Color(0x80EDEAE2),
  card: const Color(0xFF1A1F1C),
);
