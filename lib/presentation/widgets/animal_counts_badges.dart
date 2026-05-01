import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text_pluralization.dart';
import '../../domain/models/animal_count.dart';
import '../../state/providers.dart';

enum AnimalCountsBadgesMode { compact, detailed }

/// Renders a list of [AnimalCount]s as a textual badge.
///
/// In [AnimalCountsBadgesMode.compact], counts are summed by species:
/// `"17 Mouton, 4 Cheval"`. Used in list / popup contexts where space
/// is tight.
///
/// In [AnimalCountsBadgesMode.detailed], each species is followed by its
/// per-category breakdown: `"Mouton — 5 Petit + 12 Grand · Cheval — 4 Adulte"`.
/// Used on detail screens.
///
/// Resolves species and category names from [categoryLookupProvider].
/// Counts whose `categoryId` no longer resolves (truly deleted, never
/// soft-archived) are skipped silently. Empty input or all zero-counts
/// renders nothing.
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
    final lookupAsync = ref.watch(categoryLookupProvider);
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

        final text = mode == AnimalCountsBadgesMode.compact
            ? perSpecies.entries
                .map((e) =>
                    '${e.value.total} ${pluralizeFr(e.key, e.value.total)}')
                .join(', ')
            : perSpecies.entries
                .map((e) =>
                    '${pluralizeFr(e.key, e.value.total)} — ${e.value.formatBreakdown()}')
                .join('  ·  ');

        return Text(text, style: style);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
