// lib/presentation/widgets/app_diff_row.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

enum DiffStatus { same, up, down, bonus }

class DiffResult {
  final DiffStatus status;
  final int delta;
  const DiffResult(this.status, this.delta);
}

/// Affiche prévu → effectué côte à côte avec delta visuel. Utilisé sur le
/// Tour completion screen.
///
/// `planned == 0 && actual > 0` → `DiffStatus.bonus` (presta hors-plan).
/// `planned > 0 && actual == planned` → `same`.
/// `actual > planned` → `up`. `actual < planned` → `down`.
class AppDiffRow extends StatelessWidget {
  final String label;
  final int planned;
  final int actual;
  final String? amountLabel; // ex. "180 €"

  const AppDiffRow({
    super.key,
    required this.label,
    required this.planned,
    required this.actual,
    this.amountLabel,
  });

  static DiffResult computeDelta({required int planned, required int actual}) {
    if (planned == 0 && actual > 0) {
      return DiffResult(DiffStatus.bonus, actual);
    }
    final d = actual - planned;
    if (d == 0) return const DiffResult(DiffStatus.same, 0);
    if (d > 0) return DiffResult(DiffStatus.up, d);
    return DiffResult(DiffStatus.down, d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final r = computeDelta(planned: planned, actual: actual);

    final (icon, color) = switch (r.status) {
      DiffStatus.same => (FIcons.check, theme.colors.mutedForeground),
      DiffStatus.up => (FIcons.arrowUp, theme.colors.primary),
      DiffStatus.down => (FIcons.arrowDown, theme.colors.destructive),
      DiffStatus.bonus => (FIcons.plus, theme.colors.secondary),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.typography.md.copyWith(
                color: theme.colors.foreground,
              ),
            ),
          ),
          if (planned > 0)
            Text(
              'prévu $planned',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          Icon(FIcons.chevronRight, size: 12, color: theme.colors.mutedForeground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$actual',
            style: tabularStyle(theme.typography.md).copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(icon, size: 14, color: color),
          if (amountLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 60,
              child: Text(
                amountLabel!,
                textAlign: TextAlign.end,
                style: tabularStyle(theme.typography.sm).copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
