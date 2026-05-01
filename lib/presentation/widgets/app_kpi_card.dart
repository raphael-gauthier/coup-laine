// lib/presentation/widgets/app_kpi_card.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Single KPI card : grand chiffre `display 36` en accent cuivre, label
/// caption UPPERCASE muted, optional delta vs période précédente.
class AppKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final String? delta;       // ex. "+12 %", "-3"
  final bool? deltaPositive; // null = neutre, true = primary, false = destructive
  final Widget? sparkline;   // optionnel — un widget custom 8-12 points

  const AppKpiCard({
    super.key,
    required this.value,
    required this.label,
    this.delta,
    this.deltaPositive,
    this.sparkline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final valueStyle = tabularStyle(theme.typography.xl4).copyWith(
      color: theme.colors.secondary, // accent cuivre
    );
    final labelStyle = captionStyle(theme.typography.xs).copyWith(
      color: theme.colors.mutedForeground,
    );

    Color deltaColor;
    if (deltaPositive == true) {
      deltaColor = theme.colors.primary;
    } else if (deltaPositive == false) {
      deltaColor = theme.colors.destructive;
    } else {
      deltaColor = theme.colors.mutedForeground;
    }

    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.colors.border,
          width: AppSizes.hairlineBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: labelStyle),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: valueStyle),
              if (delta != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    delta!,
                    style: tabularStyle(theme.typography.sm).copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (sparkline != null) ...[
            const SizedBox(height: AppSpacing.sm),
            sparkline!,
          ],
        ],
      ),
    );
  }
}
