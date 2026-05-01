// lib/presentation/widgets/app_option_tile.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Tile de choix d'option avec indicateur checkbox carré 22dp à droite.
///
/// Pattern unifié v3 pour tous les sélecteurs (single ou multi). Le caller
/// gère le state (radio vs multi) et passe `checked` + `onChanged`.
///
/// Visual :
/// - Unchecked : carré 22×22 radius 6 avec border `border` 1.5px.
/// - Checked   : fond `primary`, icône `check` `primaryForeground` 14px.
///
/// Slots :
/// - `leading` (optionnel) : dot 16dp colored ou icône Lucide pour rappel
///   visuel (couleur statut, pictogramme apparence, etc.).
/// - `title` : label principal.
/// - `subtitle` (optionnel) : sous-texte muted.
class AppOptionTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const AppOptionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final disabled = onChanged == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged!(!checked);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.md.copyWith(
                      color: disabled
                          ? theme.colors.mutedForeground
                          : theme.colors.foreground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      subtitle!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _Checkbox(checked: checked, disabled: disabled),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final bool disabled;

  const _Checkbox({required this.checked, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? theme.colors.primary : null,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: checked
            ? null
            : Border.all(
                color: disabled ? theme.colors.muted : theme.colors.border,
                width: 1.5,
              ),
      ),
      alignment: Alignment.center,
      child: checked
          ? Icon(FIcons.check,
              color: theme.colors.primaryForeground, size: 14)
          : null,
    );
  }
}
