// lib/presentation/widgets/app_list_tile.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Variants supportés.
enum AppListTileVariant {
  /// 1 ligne : prefix + title + suffix.
  compact,

  /// 2 lignes : title + subtitle italic.
  standard,

  /// 3-4 lignes : title + subtitle italic + metadata + suffix.
  rich,
}

/// Tile v3 Modern Craft pour listes denses. Surface, hairline border,
/// padding 14×16. Remplace les usages directs de `FTile`.
///
/// `metadata` n'est utilisé qu'en variant `rich`.
class AppListTile extends StatefulWidget {
  final AppListTileVariant variant;
  final Widget? prefix;
  final String title;
  final String? subtitle;       // Rendu italique en standard et rich
  final Widget? metadata;       // Row d'AppStat ou similaire — rich uniquement
  final Widget? suffix;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppListTile({
    super.key,
    this.variant = AppListTileVariant.standard,
    this.prefix,
    required this.title,
    this.subtitle,
    this.metadata,
    this.suffix,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Aliases for the previous Stateless API to minimize the diff below.
    final variant = widget.variant;
    final prefix = widget.prefix;
    final title = widget.title;
    final subtitle = widget.subtitle;
    final metadata = widget.metadata;
    final suffix = widget.suffix;
    final onTap = widget.onTap;
    final onLongPress = widget.onLongPress;

    final titleStyle = theme.typography.lg.copyWith(
      color: theme.colors.foreground,
    );
    final subtitleStyle = theme.typography.sm.copyWith(
      color: theme.colors.mutedForeground,
      fontStyle: FontStyle.italic,
    );

    Widget content;
    switch (variant) {
      case AppListTileVariant.compact:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix,
            ],
          ],
        );
        break;

      case AppListTileVariant.standard:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(subtitle,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix,
            ],
          ],
        );
        break;

      case AppListTileVariant.rich:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(subtitle,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (metadata != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    metadata,
                  ],
                ],
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              suffix,
            ],
          ],
        );
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      onLongPress: onLongPress == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onLongPress();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: theme.colors.border,
                width: AppSizes.hairlineBorder,
              ),
            ),
            padding: AppSizes.listTilePadding,
            child: content,
          ),
        ),
      ),
    );
  }
}
