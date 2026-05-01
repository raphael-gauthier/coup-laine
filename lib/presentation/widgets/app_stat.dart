// lib/presentation/widgets/app_stat.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Micro-composant inline : `<icon> <number tabular> <unit muted>`.
/// Brique de base des KPIs et des metadata rows.
class AppStat extends StatelessWidget {
  final IconData? icon;
  final Widget? leading; // Pour passer un SvgPicture (pictogramme custom)
  final String value;
  final String? unit;
  final Color? valueColor;
  final double iconSize;

  const AppStat({
    super.key,
    this.icon,
    this.leading,
    required this.value,
    this.unit,
    this.valueColor,
    this.iconSize = 14,
  }) : assert(icon == null || leading == null, 'icon ou leading, pas les deux');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final valueStyle = tabularStyle(theme.typography.sm).copyWith(
      color: valueColor ?? theme.colors.foreground,
      fontWeight: FontWeight.w600,
    );
    final unitStyle = theme.typography.sm.copyWith(
      color: theme.colors.mutedForeground,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) leading!,
        if (icon != null)
          Icon(icon, size: iconSize, color: theme.colors.mutedForeground),
        if (icon != null || leading != null)
          const SizedBox(width: AppSpacing.xxs),
        Text(value, style: valueStyle),
        if (unit != null) ...[
          const SizedBox(width: 2),
          Text(unit!, style: unitStyle),
        ],
      ],
    );
  }
}
