// lib/presentation/widgets/app_timeline_row.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Ligne d'historique dense. Indicateur date à gauche, pictogramme métier,
/// titre court, breakdown italic, montant + durée tabular à droite.
class AppTimelineRow extends StatelessWidget {
  final String dateLabel;       // ex. "03 sept 2025"
  final IconData icon;          // FIcons.scissors / FIcons.pencil
  final String title;           // ex. "Tournée #128"
  final String? breakdown;      // ex. "3 Tonte Petit · 1 Parage" (rendu italic)
  final String? amount;         // ex. "180 €"
  final String? duration;       // ex. "45m"
  final VoidCallback? onTap;

  const AppTimelineRow({
    super.key,
    required this.dateLabel,
    required this.icon,
    required this.title,
    this.breakdown,
    this.amount,
    this.duration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date verticale à gauche
            SizedBox(
              width: 70,
              child: Text(
                dateLabel,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            // Pictogramme + content
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colors.muted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 14, color: theme.colors.foreground),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),
                  if (breakdown != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      breakdown!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Montant + durée à droite (tabular)
            if (amount != null || duration != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (amount != null)
                    Text(
                      amount!,
                      style: tabularStyle(theme.typography.sm).copyWith(
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (duration != null) ...[
                    if (amount != null) const SizedBox(height: 2),
                    Text(
                      duration!,
                      style: tabularStyle(theme.typography.sm).copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
