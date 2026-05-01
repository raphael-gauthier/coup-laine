// lib/presentation/widgets/app_kpi_row.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Une « cellule » de KpiRow : valeur tabular + label caption.
class AppKpiCell {
  final String value;
  final String label;
  final Color? valueColor; // null → foreground ; spec : accent cuivre pour le chiffre principal
  const AppKpiCell({
    required this.value,
    required this.label,
    this.valueColor,
  });
}

/// Rangée de 2-4 mini-KPIs côte à côte, séparés par hairlines verticales
/// (0.5px). Surface (`card`), border 0.5px, padding 16dp vertical.
///
/// Ex. usage Tour detail : `AppKpiRow(cells: [
///   AppKpiCell(value: '47.2', label: 'km'),
///   AppKpiCell(value: '6h12', label: 'durée'),
///   AppKpiCell(value: '480 €', label: 'revenu', valueColor: ...accent),
///   AppKpiCell(value: '12', label: 'animaux'),
/// ])`.
class AppKpiRow extends StatelessWidget {
  final List<AppKpiCell> cells;

  const AppKpiRow({super.key, required this.cells})
      : assert(cells.length >= 2 && cells.length <= 4,
            'AppKpiRow accepte 2 à 4 cellules');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final valueStyle = tabularStyle(theme.typography.xl).copyWith(
      color: theme.colors.foreground,
      fontWeight: FontWeight.w600,
    );
    final labelStyle = captionStyle(theme.typography.xs).copyWith(
      color: theme.colors.mutedForeground,
    );

    final children = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      children.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  c.value,
                  maxLines: 1,
                  softWrap: false,
                  style: valueStyle.copyWith(
                    color: c.valueColor ?? theme.colors.foreground,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(c.label.toUpperCase(), style: labelStyle),
            ],
          ),
        ),
      ));
      if (i < cells.length - 1) {
        children.add(Container(
          width: AppSizes.hairlineBorder,
          color: theme.colors.border,
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.colors.border,
          width: AppSizes.hairlineBorder,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
