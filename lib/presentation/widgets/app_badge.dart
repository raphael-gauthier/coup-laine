import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../domain/use_cases/client_status.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const AppBadge._({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  factory AppBadge.waiting(BuildContext context, {String label = 'En attente'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.clock,
      background: colors.secondary,
      foreground: colors.secondaryForeground,
    );
  }

  factory AppBadge.fromStatus(
    BuildContext context, {
    required ClientStatus status,
    required String label,
  }) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: switch (status) {
        ClientStatus.defaultStatus => FIcons.circle,
        ClientStatus.waiting => FIcons.clock,
        ClientStatus.scheduled => FIcons.calendar,
        ClientStatus.done => FIcons.check,
        ClientStatus.noAnimals => FIcons.x,
        ClientStatus.banned => FIcons.ban,
      },
      background: switch (status) {
        ClientStatus.banned => colors.destructive,
        ClientStatus.waiting => colors.secondary,
        _ => colors.muted,
      },
      foreground: switch (status) {
        ClientStatus.banned => colors.destructiveForeground,
        ClientStatus.waiting => colors.secondaryForeground,
        _ => colors.foreground,
      },
    );
  }

  factory AppBadge.recompute(BuildContext context, {String label = 'Distances'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.refreshCw,
      background: colors.muted,
      foreground: colors.mutedForeground,
    );
  }

  factory AppBadge.completed(BuildContext context, {String label = 'Réalisée'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.check,
      background: colors.primary,
      foreground: colors.primaryForeground,
    );
  }

  factory AppBadge.planned(BuildContext context, {String label = 'Planifiée'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.calendar,
      background: colors.secondary,
      foreground: colors.secondaryForeground,
    );
  }

  factory AppBadge.longDay(BuildContext context, {String label = 'Journée longue'}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: FIcons.sunset,
      background: colors.muted,
      foreground: colors.foreground,
    );
  }

  /// Nouveau v3 — succès générique.
  factory AppBadge.success(BuildContext context, {required String label, IconData? icon}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: icon ?? FIcons.check,
      background: colors.primary,
      foreground: colors.primaryForeground,
    );
  }

  /// Nouveau v3 — info neutre.
  factory AppBadge.info(BuildContext context, {required String label, IconData? icon}) {
    final colors = context.theme.colors;
    return AppBadge._(
      label: label,
      icon: icon,
      background: colors.muted,
      foreground: colors.foreground,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
