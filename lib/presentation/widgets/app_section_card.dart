import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

class AppSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconBackground;

  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bg = iconBackground ?? theme.colors.secondary;
    final fg = theme.colors.secondaryForeground;

    return FCard.raw(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: AppSizes.sectionIconCircle,
                  height: AppSizes.sectionIconCircle,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: fg, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.typography.xl2.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
