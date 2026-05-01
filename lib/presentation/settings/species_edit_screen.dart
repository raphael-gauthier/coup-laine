import 'package:flutter/material.dart' show Icons, IconButton, showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/species.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import 'animal_category_form_sheet.dart';

/// Per-species edit screen, route `/settings/species/:id`.
class SpeciesEditScreen extends ConsumerStatefulWidget {
  final int speciesId;
  const SpeciesEditScreen({super.key, required this.speciesId});

  @override
  ConsumerState<SpeciesEditScreen> createState() => _SpeciesEditScreenState();
}

class _SpeciesEditScreenState extends ConsumerState<SpeciesEditScreen> {
  Future<_SpeciesEditData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SpeciesEditData> _load() async {
    final speciesRepo = ref.read(speciesRepositoryProvider);
    final catsRepo = ref.read(animalCategoryRepositoryProvider);
    final all = await speciesRepo.listAll();
    final matches = all.where((s) => s.id == widget.speciesId);
    final species = matches.isEmpty ? null : matches.first;
    final categories = await catsRepo.listAllBySpecies(widget.speciesId);
    final activeCount = await speciesRepo.countActive();
    return _SpeciesEditData(
      species: species,
      categories: categories,
      activeSpeciesCount: activeCount,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _invalidateUpstream() {
    ref.invalidate(activeSpeciesProvider);
    ref.invalidate(archivedSpeciesProvider);
    ref.invalidate(activeCategoriesBySpeciesProvider);
    ref.invalidate(allCategoriesByIdProvider);
    ref.invalidate(categoryDisplayInfoProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.speciesManagementTitle)),
        child: FutureBuilder<_SpeciesEditData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: FCircularProgress());
            }
            if (snap.hasError) {
              return Center(child: Text('${snap.error}'));
            }
            final data = snap.data!;
            if (data.species == null) {
              return const Center(child: Text('—'));
            }
            return _SpeciesEditBody(
              data: data,
              onMutated: () {
                _invalidateUpstream();
                _reload();
              },
            );
          },
        ),
      ),
    );
  }
}

class _SpeciesEditData {
  final Species? species;
  final List<AnimalCategory> categories;
  final int activeSpeciesCount;
  const _SpeciesEditData({
    required this.species,
    required this.categories,
    required this.activeSpeciesCount,
  });
}

class _SpeciesEditBody extends ConsumerStatefulWidget {
  final _SpeciesEditData data;
  final VoidCallback onMutated;

  const _SpeciesEditBody({
    required this.data,
    required this.onMutated,
  });

  @override
  ConsumerState<_SpeciesEditBody> createState() => _SpeciesEditBodyState();
}

class _SpeciesEditBodyState extends ConsumerState<_SpeciesEditBody> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data.species!.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;
    if (newName == widget.data.species!.name) return;
    await ref
        .read(speciesRepositoryProvider)
        .rename(id: widget.data.species!.id, name: newName);
    widget.onMutated();
  }

  Future<void> _toggleArchive() async {
    final species = widget.data.species!;
    final repo = ref.read(speciesRepositoryProvider);
    if (species.isArchived) {
      await repo.unarchive(species.id);
    } else {
      await repo.archive(species.id);
    }
    widget.onMutated();
  }

  Future<void> _addCategory() async {
    final result = await showModalBottomSheet<AnimalCategoryFormSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AnimalCategoryFormSheet(),
    );
    if (result == null) return;
    await ref.read(animalCategoryRepositoryProvider).insert(
          speciesId: widget.data.species!.id,
          name: result.name,
        );
    widget.onMutated();
  }

  Future<void> _editCategory(AnimalCategory cat) async {
    final result = await showModalBottomSheet<AnimalCategoryFormSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnimalCategoryFormSheet(
        initialName: cat.name,
      ),
    );
    if (result == null) return;
    final repo = ref.read(animalCategoryRepositoryProvider);
    if (result.name != cat.name) {
      await repo.rename(id: cat.id, name: result.name);
    }
    widget.onMutated();
  }

  Future<void> _archiveCategory(AnimalCategory cat) async {
    await ref.read(animalCategoryRepositoryProvider).archive(cat.id);
    widget.onMutated();
  }

  Future<void> _unarchiveCategory(AnimalCategory cat) async {
    await ref.read(animalCategoryRepositoryProvider).unarchive(cat.id);
    widget.onMutated();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final species = widget.data.species!;
    final activeCats =
        widget.data.categories.where((c) => !c.isArchived).toList();
    final archivedCats =
        widget.data.categories.where((c) => c.isArchived).toList();
    final canArchiveSpecies =
        species.isArchived || widget.data.activeSpeciesCount > 1;

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            species.name,
            style: theme.typography.xl2.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FTextField(
            control: FTextFieldControl.managed(
              controller: _nameCtrl,
              onChange: (_) {},
            ),
            label: Text(l.categoryFormName),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: _saveName,
                  child: Text(l.categoryFormSave),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FButton(
                  variant: species.isArchived
                      ? FButtonVariant.outline
                      : FButtonVariant.destructive,
                  onPress: canArchiveSpecies ? _toggleArchive : null,
                  child: Text(
                    species.isArchived
                        ? l.speciesManagementUnarchive
                        : l.speciesManagementArchive,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          for (final cat in activeCats)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CategoryActiveRow(
                category: cat,
                onEdit: () => _editCategory(cat),
                onArchive: () => _archiveCategory(cat),
              ),
            ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: _addCategory,
            child: Text(l.speciesEditAddCategory),
          ),

          if (archivedCats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.speciesManagementArchivedSection,
              style: theme.typography.lg.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final cat in archivedCats)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CategoryArchivedRow(
                  category: cat,
                  onUnarchive: () => _unarchiveCategory(cat),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryActiveRow extends StatelessWidget {
  final AnimalCategory category;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _CategoryActiveRow({
    required this.category,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
        padding: AppSizes.listTilePadding,
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: theme.colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: theme.typography.md.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: onArchive,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryArchivedRow extends StatelessWidget {
  final AnimalCategory category;
  final VoidCallback onUnarchive;

  const _CategoryArchivedRow({
    required this.category,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return Container(
      padding: AppSizes.listTilePadding,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              style: theme.typography.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: onUnarchive,
            child: Text(l.categoryFormUnarchive),
          ),
        ],
      ),
    );
  }
}
