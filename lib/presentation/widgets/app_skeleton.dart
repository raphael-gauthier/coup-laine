// lib/presentation/widgets/app_skeleton.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Bloc placeholder shimmer pure-Flutter (pas de package shimmer externe).
/// Utilise un `AnimatedBuilder` qui interpole entre deux opacités sur la
/// couleur `surfaceMuted` (proxy : `theme.colors.muted`).
class AppSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppBorderRadius.sm,
  });

  /// Helper : skeleton pour un titre (24dp height).
  factory AppSkeleton.title({double? width}) =>
      AppSkeleton(height: 24, width: width, radius: AppBorderRadius.sm);

  /// Helper : skeleton pour un body line (16dp height).
  factory AppSkeleton.line({double? width}) =>
      AppSkeleton(height: 16, width: width, radius: AppBorderRadius.sm);

  /// Helper : skeleton pour un tile (72dp height).
  factory AppSkeleton.tile() =>
      const AppSkeleton(height: 72, radius: AppBorderRadius.md);

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.colors.muted,
              theme.colors.border,
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
