import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/avatar_icons.dart';

/// Horizontal scrollable list of avatar chips, one per [kAvatarKeys] entry.
/// Selection is single-choice. Tapping a chip calls [onSelect] with the
/// new key.
class AvatarPicker extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  const AvatarPicker({
    super.key,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final current = selectedKey ?? kDefaultAvatarKey;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kAvatarKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final key = kAvatarKeys[i];
          final isSelected = key == current;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colors.primary.withValues(alpha: 0.15)
                    : theme.colors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colors.primary
                      : theme.colors.border,
                ),
              ),
              child: Icon(
                iconForAvatarKey(key),
                size: 28,
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.foreground,
              ),
            ),
          );
        },
      ),
    );
  }
}
