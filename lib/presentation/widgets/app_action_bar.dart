// lib/presentation/widgets/app_action_bar.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Action bar sticky bottom v3. Hauteur 64dp + safe-area, surface (card),
/// hairline 0.5px en haut. Contient 1 à 3 actions.
///
/// `primary` = CTA plein-largeur si rendu seul ; sinon partage la rangée
/// avec `secondary` (50/50). Si `secondary` ET `tertiary` sont fournis et
/// pas de `primary`, on rend les 3 outline répartis equal-flex.
class AppActionBar extends StatelessWidget {
  final Widget? primary;
  final Widget? secondary;
  final Widget? tertiary;

  const AppActionBar({
    super.key,
    this.primary,
    this.secondary,
    this.tertiary,
  }) : assert(primary != null || secondary != null || tertiary != null,
            'au moins une action');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final children = <Widget>[];

    if (primary != null && secondary == null && tertiary == null) {
      children.add(Expanded(child: primary!));
    } else if (primary != null && secondary != null) {
      children.addAll([
        Expanded(child: secondary!),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: primary!),
      ]);
    } else {
      // 2 ou 3 outline répartis
      if (tertiary != null) children.add(Expanded(child: tertiary!));
      if (secondary != null) {
        if (children.isNotEmpty) children.add(const SizedBox(width: AppSpacing.sm));
        children.add(Expanded(child: secondary!));
      }
      if (primary != null) {
        if (children.isNotEmpty) children.add(const SizedBox(width: AppSpacing.sm));
        children.add(Expanded(child: primary!));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(
          top: BorderSide(
            color: theme.colors.border,
            width: AppSizes.hairlineBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: children,
        ),
      ),
    );
  }
}
