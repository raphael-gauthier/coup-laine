// lib/presentation/widgets/app_fab.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// FAB v3. Variante `regular` (56dp circulaire) ou `extended` (56dp pill
/// avec label). Utilise `primary` fill. Position bottom-right gérée par
/// le caller (typiquement dans un `Stack`).
class AppFAB extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPress;
  final bool extended;

  const AppFAB({
    super.key,
    required this.icon,
    required this.onPress,
    this.label,
    this.extended = false,
  }) : assert(!extended || label != null,
            'AppFAB extended exige un label');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = extended ? AppBorderRadius.pill : 999.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPress == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPress!();
            },
      child: Container(
        height: 56,
        width: extended ? null : 56,
        padding: extended
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
            : null,
        decoration: BoxDecoration(
          color: theme.colors.primary,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: theme.colors.primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colors.primaryForeground, size: 22),
            if (extended) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                label!,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.primaryForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
