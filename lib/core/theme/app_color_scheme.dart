// lib/core/theme/app_color_scheme.dart
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

// ignore: avoid_redundant_argument_values
final FColors appLightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  background: const Color(0xFFF8F4ED),
  foreground: const Color(0xFF1F1B16),
  primary: const Color(0xFF4A6B52),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFC77B5C),
  secondaryForeground: const Color(0xFFFFFFFF),
  muted: const Color(0xFFEFEAE0),
  mutedForeground: const Color(0xFF6B6359),
  destructive: const Color(0xFFB33A3A),
  destructiveForeground: const Color(0xFFFFFFFF),
  error: const Color(0xFFB33A3A),
  errorForeground: const Color(0xFFFFFFFF),
  border: const Color(0xFFE8E1D4),
  barrier: const Color(0x801F1B16),
  card: const Color(0xFFFFFFFF),
);

// ignore: avoid_redundant_argument_values
final FColors appDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  background: const Color(0xFF1F1B16),
  foreground: const Color(0xFFF5F0E8),
  primary: const Color(0xFF7C9C7E),
  primaryForeground: const Color(0xFF1F1B16),
  secondary: const Color(0xFFE0926D),
  secondaryForeground: const Color(0xFF1F1B16),
  muted: const Color(0xFF2B2620),
  mutedForeground: const Color(0xFFA89F92),
  destructive: const Color(0xFFD45A5A),
  destructiveForeground: const Color(0xFF1F1B16),
  error: const Color(0xFFD45A5A),
  errorForeground: const Color(0xFF1F1B16),
  border: const Color(0xFF3A332A),
  barrier: const Color(0x80F5F0E8),
  card: const Color(0xFF2B2620),
);
