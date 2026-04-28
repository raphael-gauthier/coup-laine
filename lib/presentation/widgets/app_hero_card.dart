import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

class AppHeroCard extends StatelessWidget {
  final Widget? badge;
  final String bigNumber;
  final String label;
  final String? subtitle;

  const AppHeroCard({
    super.key,
    required this.bigNumber,
    required this.label,
    this.badge,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.colors.brightness == Brightness.dark;

    return Container(
      padding: AppSizes.heroCardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2B2620), const Color(0xFF1F1B16)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1EBDF)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.sm),
          bottomLeft: Radius.circular(AppBorderRadius.sm),
          bottomRight: Radius.circular(AppBorderRadius.sm),
        ),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            badge!,
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bigNumber,
                style: theme.typography.xl4.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
