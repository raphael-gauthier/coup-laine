import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/animal_counts_normalizer.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/species.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

/// Controlled editor for a [List<AnimalCount>].
///
/// Renders one accordion section per active species, each containing rows of
/// `(category name, numeric input)`. Counts are emitted through [onChanged]
/// after being normalized via [normalizeAnimalCounts] (zero-counts dropped,
/// dedup'd by categoryId, sorted ascending).
///
/// If [value] contains entries whose categoryId resolves to an archived
/// category, an extra "archived" section is rendered with read-only rows and
/// an "Effacer" button per row.
class AnimalCountsEditor extends ConsumerStatefulWidget {
  final List<AnimalCount> value;
  final ValueChanged<List<AnimalCount>> onChanged;

  const AnimalCountsEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<AnimalCountsEditor> createState() =>
      _AnimalCountsEditorState();
}

class _AnimalCountsEditorState extends ConsumerState<AnimalCountsEditor> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void didUpdateWidget(AnimalCountsEditor old) {
    super.didUpdateWidget(old);
    _reconcileControllers();
  }

  TextEditingController _controllerFor(int categoryId, int initialCount) {
    return _controllers.putIfAbsent(categoryId, () {
      final c = TextEditingController(
        text: initialCount == 0 ? '' : initialCount.toString(),
      );
      c.addListener(() => _onTextChanged(categoryId, c.text));
      return c;
    });
  }

  void _reconcileControllers() {
    final byId = {for (final ac in widget.value) ac.categoryId: ac.count};
    for (final entry in _controllers.entries) {
      final newCount = byId[entry.key] ?? 0;
      final newText = newCount == 0 ? '' : newCount.toString();
      final currentParsed = int.tryParse(entry.value.text) ?? 0;
      if (currentParsed != newCount && entry.value.text != newText) {
        entry.value.text = newText;
      }
    }
  }

  void _onTextChanged(int categoryId, String text) {
    final parsed = int.tryParse(text) ?? 0;
    final byId = {for (final ac in widget.value) ac.categoryId: ac.count};
    if (parsed <= 0) {
      byId.remove(categoryId);
    } else {
      byId[categoryId] = parsed;
    }
    final next = normalizeAnimalCounts([
      for (final e in byId.entries)
        AnimalCount(categoryId: e.key, count: e.value),
    ]);
    if (_listsEqual(next, widget.value)) return;
    widget.onChanged(next);
  }

  bool _listsEqual(List<AnimalCount> a, List<AnimalCount> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _clearArchived(int categoryId) {
    final next = normalizeAnimalCounts([
      for (final ac in widget.value)
        if (ac.categoryId != categoryId) ac,
    ]);
    widget.onChanged(next);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final speciesAsync = ref.watch(activeSpeciesProvider);
    final categoriesAsync = ref.watch(activeCategoriesBySpeciesProvider);
    final allCategoriesAsync = ref.watch(allCategoriesByIdProvider);

    final activeSpecies = speciesAsync.asData?.value;
    final categoriesBySpecies = categoriesAsync.asData?.value;
    final allCategories = allCategoriesAsync.asData?.value;

    if (activeSpecies == null ||
        categoriesBySpecies == null ||
        allCategories == null) {
      return const SizedBox.shrink();
    }

    if (activeSpecies.isEmpty) {
      return Text(l.animalCountsEditorEmpty);
    }

    final archivedEntries = [
      for (final ac in widget.value)
        if (allCategories[ac.categoryId]?.isArchived ?? false) ac,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < activeSpecies.length; i++)
          _buildSpeciesPanel(
            context,
            species: activeSpecies[i],
            categories: categoriesBySpecies[activeSpecies[i].id] ?? const [],
            initiallyExpanded: i == 0,
          ),
        if (archivedEntries.isNotEmpty)
          _buildArchivedSection(
            context,
            entries: archivedEntries,
            allCategories: allCategories,
            l: l,
          ),
      ],
    );
  }

  Widget _buildSpeciesPanel(
    BuildContext context, {
    required Species species,
    required List<AnimalCategory> categories,
    required bool initiallyExpanded,
  }) {
    final byId = {for (final ac in widget.value) ac.categoryId: ac.count};
    return ExpansionTile(
      title: Text(species.name),
      initiallyExpanded: initiallyExpanded,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final cat in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(cat.name)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controllerFor(cat.id, byId[cat.id] ?? 0),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: '0',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildArchivedSection(
    BuildContext context, {
    required List<AnimalCount> entries,
    required Map<int, AnimalCategory> allCategories,
    required AppLocalizations l,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              l.animalCountsArchivedSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final ac in entries)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ac.count} ${allCategories[ac.categoryId]?.name ?? ''}',
                    ),
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    onPress: () => _clearArchived(ac.categoryId),
                    child: Text(l.animalCountsClear),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
