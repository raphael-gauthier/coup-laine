// lib/presentation/widgets/app_section_card.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Card de section v3 Modern Craft : surface (card), 0.5px hairline border,
/// padding 20dp, header avec icon 28dp + title-md (`theme.typography.xl`).
///
/// L'icône a un fond `surfaceMuted` par défaut (au lieu de secondary forcé).
/// Le caller peut override avec `iconBackground`/`iconForeground`.
class AppSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconBackground;
  final Color? iconForeground;
  final Widget? trailing;

  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconBackground,
    this.iconForeground,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bg = iconBackground ?? theme.colors.muted;
    final fg = iconForeground ?? theme.colors.foreground;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.colors.border,
          width: AppSizes.hairlineBorder,
        ),
      ),
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
                child: Icon(icon, color: fg, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.xl.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
