// lib/presentation/widgets/app_header.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';

/// Action décrite côté caller. Si la largeur disponible permet le label,
/// on rend `[icon] label` ; sinon on rend juste l'icône (touch target 44dp,
/// le tooltip Forui montre le label sur tap-and-hold).
class AppHeaderAction {
  final IconData icon;
  final String label;
  final VoidCallback? onPress;
  final bool destructive;

  const AppHeaderAction({
    required this.icon,
    required this.label,
    required this.onPress,
    this.destructive = false,
  });
}

/// Header v3. Hauteur ~64dp + padding horizontal. `[back?] [title-lg + subtitle?]
/// [trailing actions]`. Les actions affichent leur label si la width
/// disponible ≥ 360dp, sinon icon-only avec tooltip.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<AppHeaderAction> actions;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.actions = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final labelMode = MediaQuery.sizeOf(context).width >= 360;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            FButton.icon(
              onPress: onBack ?? () => context.pop(),
              child: const Icon(FIcons.chevronLeft),
            ),
          if (showBackButton) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.typography.xl2.copyWith(
                    color: theme.colors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    subtitle!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[
            const SizedBox(width: AppSpacing.xs),
            _renderAction(context, a, labelMode: labelMode),
          ],
        ],
      ),
    );
  }

  Widget _renderAction(BuildContext context, AppHeaderAction a,
      {required bool labelMode}) {
    if (labelMode) {
      return FButton(
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        prefix: Icon(a.icon),
        onPress: a.onPress,
        child: Text(a.label),
      );
    }
    return FButton.icon(onPress: a.onPress, child: Icon(a.icon));
  }
}
