// lib/presentation/widgets/app_command_palette.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Item présenté dans la palette : un label, une icône, une action onSelect.
class AppCommandItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onSelect;

  const AppCommandItem({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.subtitle,
  });
}

/// Sheet full-screen de recherche universelle. Le caller fournit les items
/// (typiquement construits depuis des providers dans Plan 2). Filtrage
/// case-insensitive substring sur `label` + `subtitle`.
class AppCommandPalette extends StatefulWidget {
  final List<AppCommandItem> items;
  final String hint;

  const AppCommandPalette({
    super.key,
    required this.items,
    this.hint = 'Recherche…',
  });

  /// Helper d'ouverture en bottom sheet plein-écran.
  static Future<void> show(BuildContext context,
      {required List<AppCommandItem> items, String hint = 'Recherche…'}) {
    return showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (ctx) => Padding(
        padding: MediaQuery.viewInsetsOf(ctx),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.9,
          child: AppCommandPalette(items: items, hint: hint),
        ),
      ),
    );
  }

  @override
  State<AppCommandPalette> createState() => _AppCommandPaletteState();
}

class _AppCommandPaletteState extends State<AppCommandPalette> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((i) {
            final hay = '${i.label} ${i.subtitle ?? ''}'.toLowerCase();
            return hay.contains(q);
          }).toList();

    return Container(
      color: theme.colors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          FTextField(
            control: FTextFieldControl.managed(
              controller: _controller,
              onChange: (v) => setState(() => _query = v.text),
            ),
            hint: widget.hint,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun résultat',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xxs),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).pop();
                          item.onSelect();
                        },
                        child: Container(
                          padding: AppSizes.listTilePadding,
                          decoration: BoxDecoration(
                            color: theme.colors.card,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                              color: theme.colors.border,
                              width: AppSizes.hairlineBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon,
                                  size: 18, color: theme.colors.foreground),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.label,
                                        style: theme.typography.lg.copyWith(
                                          color: theme.colors.foreground,
                                        )),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: AppSpacing.xxxs),
                                      Text(
                                        item.subtitle!,
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.mutedForeground,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(FIcons.chevronRight,
                                  size: 16,
                                  color: theme.colors.mutedForeground),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
