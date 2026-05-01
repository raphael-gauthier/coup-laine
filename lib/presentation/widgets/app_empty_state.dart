// lib/presentation/widgets/app_empty_state.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// État vide v3 Modern Craft. Centré, généreux. Soit une illustration
/// (asset SVG existant `assets/illustrations/`) soit un pictogramme
/// `IconData` (Lucide via FIcons) en `subtleForeground`.
class AppEmptyState extends StatelessWidget {
  final String? illustrationAsset;
  final IconData? icon;
  final String title;
  final String body;
  final Widget? action;
  final Widget? secondaryAction;
  final double illustrationHeight;

  const AppEmptyState({
    super.key,
    this.illustrationAsset,
    this.icon,
    required this.title,
    required this.body,
    this.action,
    this.secondaryAction,
    this.illustrationHeight = 120,
  }) : assert(
          (illustrationAsset != null) ^ (icon != null),
          'fournir soit illustrationAsset soit icon (exclusif)',
        );

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.huge,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (illustrationAsset != null)
            SvgPicture.asset(
              illustrationAsset!,
              height: illustrationHeight,
              fit: BoxFit.contain,
            )
          else
            Icon(
              icon!,
              size: AppSizes.heroIconCircle,
              // subtleForeground n'existe pas dans FColors ; on utilise muted
              // comme proxy. Plan 2 introduira un wrapper si besoin.
              color: theme.colors.mutedForeground,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.typography.xl2.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.typography.md.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
          if (secondaryAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}
