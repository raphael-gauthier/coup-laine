import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';

import '../../core/animal_icons.dart';
import '../../core/design_tokens.dart';
import '../../core/text_pluralization.dart';
import '../../domain/models/animal_count.dart';
import '../../state/providers.dart';

enum AnimalCountsBadgesMode { compact, detailed }

/// Renders a list of [AnimalCount]s.
///
/// In [AnimalCountsBadgesMode.compact], counts are summed by species and
/// rendered as a single Text: `"17 Mouton, 4 Cheval"`. Used in list / popup
/// contexts where space is tight.
///
/// In [AnimalCountsBadgesMode.detailed], each species is rendered as a
/// mini-row `<species-icon> <species-name> — <breakdown>`, wrapped together.
/// Icons resolve via [iconAssetForSpeciesKey] (seed species names match the
/// lowercase iconKey: Mouton → mouton, Cheval → cheval, etc.). Custom species
/// fall back to `FIcons.pawPrint`.
///
/// Resolves species and category names from [categoryDisplayInfoProvider].
/// Counts whose `categoryId` no longer resolves are skipped silently. Empty
/// input or all-zero counts render nothing.
class AnimalCountsBadges extends ConsumerWidget {
  final List<AnimalCount> counts;
  final AnimalCountsBadgesMode mode;
  final TextStyle? style;

  const AnimalCountsBadges({
    super.key,
    required this.counts,
    required this.mode,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final lookupAsync = ref.watch(categoryDisplayInfoProvider);
    return lookupAsync.when(
      data: (lookup) {
        final perSpecies = <String, _Bucket>{};
        for (final ac in counts) {
          if (ac.count <= 0) continue;
          final entry = lookup[ac.categoryId];
          if (entry == null) continue;
          perSpecies
              .putIfAbsent(entry.speciesName, () => _Bucket())
              .add(entry.categoryName, ac.count);
        }
        if (perSpecies.isEmpty) return const SizedBox.shrink();

        if (mode == AnimalCountsBadgesMode.compact) {
          final text = perSpecies.entries
              .map((e) =>
                  '${e.value.total} ${pluralizeFr(e.key, e.value.total)}')
              .join(', ');
          return Text(text, style: style);
        }

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: perSpecies.entries
              .map((e) => _SpeciesRow(
                    speciesName: e.key,
                    total: e.value.total,
                    breakdown: e.value.formatBreakdown(),
                    style: style,
                  ))
              .toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SpeciesRow extends StatelessWidget {
  final String speciesName;
  final int total;
  final String breakdown;
  final TextStyle? style;

  const _SpeciesRow({
    required this.speciesName,
    required this.total,
    required this.breakdown,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final asset = iconAssetForSpeciesKey(speciesName);
    final icon = asset != null
        ? SvgPicture.asset(
            asset,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              theme.colors.foreground,
              BlendMode.srcIn,
            ),
          )
        : Icon(FIcons.pawPrint, size: 16, color: theme.colors.foreground);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '${pluralizeFr(speciesName, total)} — $breakdown',
          style: style,
        ),
      ],
    );
  }
}

class _Bucket {
  int total = 0;
  final List<({String name, int count})> parts = [];

  void add(String name, int count) {
    total += count;
    parts.add((name: name, count: count));
  }

  String formatBreakdown() => parts
      .map((p) => '${p.count} ${pluralizeFr(p.name, p.count)}')
      .join(' + ');
}
