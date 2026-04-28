// lib/core/theme/app_typography.dart
import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';

/// Build a typography that swaps Fraunces in for headline-tier sizes.
/// The smaller tiers stay on the inherited (Inter) family.
FTypography buildAppTypography(FTypography base) {
  return base.copyWith(
    xl4: base.xl4.copyWith(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w800,
      fontSize: 40,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    xl3: base.xl3.copyWith(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.15,
      letterSpacing: -0.4,
    ),
    xl2: base.xl2.copyWith(
      fontFamily: 'Fraunces',
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.2,
      letterSpacing: -0.2,
    ),
  );
}
