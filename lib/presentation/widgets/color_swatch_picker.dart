// lib/presentation/widgets/color_swatch_picker.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// 16 predefined color swatches used everywhere a marker color is picked.
const List<Color> kColorSwatchPalette = <Color>[
  Color(0xFF4A6B52), // sage primary
  Color(0xFF7C9C7E), // sage light
  Color(0xFFC77B5C), // terracotta primary
  Color(0xFFE0926D), // terracotta light
  Color(0xFFB33A3A), // brick red
  Color(0xFFD45A5A), // red light
  Color(0xFF8B6F47), // brown
  Color(0xFFC9A66B), // ochre
  Color(0xFF6B6359), // muted warm gray
  Color(0xFFA89F92), // muted light
  Color(0xFF1F1B16), // anthracite
  Color(0xFF456D8C), // slate blue
  Color(0xFF7B96B0), // sky
  Color(0xFF8E6FA1), // muted purple
  Color(0xFFE8C547), // warm yellow
  Color(0xFFE07856), // coral
];

/// An inline grid of swatches. Tap a swatch → [onPicked] fires.
///
/// Used inline in the client form (per-client override) and inside the
/// dialog produced by [showColorSwatchPicker].
class ColorSwatchGrid extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onPicked;
  const ColorSwatchGrid({
    super.key,
    required this.current,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (final color in kColorSwatchPalette)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPicked(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: color.toARGB32() == current.toARGB32()
                    ? Border.all(color: theme.colors.foreground, width: 3)
                    : Border.all(color: theme.colors.border, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

/// A dialog wrapping [ColorSwatchGrid] with a title and a "Réinitialiser"
/// ghost button that returns [defaultColor].
///
/// Returns the picked color, or `null` if the user dismissed the dialog
/// (Annuler or barrier tap).
Future<Color?> showColorSwatchPicker({
  required BuildContext context,
  required Color current,
  required Color defaultColor,
  String title = 'Choisir une couleur',
}) {
  return showFDialog<Color>(
    context: context,
    builder: (ctx, style, animation) {
      final l = AppLocalizations.of(ctx)!;
      return FDialog(
        style: style,
        animation: animation,
        title: Text(title),
        body: SizedBox(
          width: 280,
          child: ColorSwatchGrid(
            current: current,
            onPicked: (c) => Navigator.of(ctx).pop(c),
          ),
        ),
        actions: [
          FButton(
            variant: FButtonVariant.ghost,
            onPress: () => Navigator.of(ctx).pop(defaultColor),
            child: Text(l.commonReset),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(ctx).pop(),
            child: Text(l.commonCancel),
          ),
        ],
      );
    },
  );
}
