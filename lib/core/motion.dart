// lib/core/motion.dart
import 'package:flutter/animation.dart';

/// Motion tokens v3 — durées et courbes standardisées.
abstract final class AppMotion {
  AppMotion._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 280);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve normalCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
}
