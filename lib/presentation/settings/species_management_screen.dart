import 'package:flutter/material.dart'
    show
        ListTile,
        TextField,
        InputDecoration,
        Material,
        Icons,
        IconButton,
        showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../data/seeds/species_seeds.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/species.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../onboarding/custom_species_form_sheet.dart';

class SpeciesManagementScreen extends ConsumerWidget {
  const SpeciesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activeSpeciesProvider);
    final archivedAsync = ref.watch(archivedSpeciesProvider);
    final catsAsync = ref.watch(activeCategoriesBySpeciesProvider);
    final theme = context.theme;

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.speciesManagementTitle)),
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (activeAsync.hasValue) ...[
                for (final species in activeAsync.value!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SpeciesActiveTile(
                      species: species,
                      categories:
                          (catsAsync.hasValue ? catsAsync.value![species.id] : null) ?? const [],
                      canArchive: activeAsync.value!.length > 1,
                      onTap: () =>
                          context.push('/settings/species/${species.id}'),
                      onRename: () => _renameSpecies(context, ref, species),
                      onArchive: () async {
                        await ref
                            .read(speciesRepositoryProvider)
                            .archive(species.id);
                        ref.invalidate(activeSpeciesProvider);
                        ref.invalidate(archivedSpeciesProvider);
                      },
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                FButton(
                  onPress: () => _addCustom(context, ref),
                  child: Text(l.speciesManagementAddSpecies),
                ),
                const SizedBox(height: AppSpacing.sm),
                FButton(
                  variant: FButtonVariant.ghost,
                  onPress: () => _restoreTemplate(
                    context,
                    ref,
                    activeAsync.value!,
                    archivedAsync.hasValue
                        ? archivedAsync.value!
                        : const <Species>[],
                  ),
                  child: Text(l.speciesManagementRestoreTemplate),
                ),
              ] else if (activeAsync.isLoading)
                const Center(child: FCircularProgress())
              else if (activeAsync.hasError)
                Text('${activeAsync.error}'),
              if (archivedAsync.hasValue &&
                  archivedAsync.value!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.speciesManagementArchivedSection,
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final species in archivedAsync.value!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SpeciesArchivedTile(
                      species: species,
                      onUnarchive: () async {
                        await ref
                            .read(speciesRepositoryProvider)
                            .unarchive(species.id);
                        ref.invalidate(activeSpeciesProvider);
                        ref.invalidate(archivedSpeciesProvider);
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameSpecies(
    BuildContext context,
    WidgetRef ref,
    Species species,
  ) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: species.name);
    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.speciesManagementRename,
                style: context.theme.typography.lg,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: AppSpacing.md),
              FButton(
                onPress: () => Navigator.of(ctx).pop(controller.text),
                child: Text(l.categoryFormSave),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (newName == null || newName.trim().isEmpty) return;
    await ref
        .read(speciesRepositoryProvider)
        .rename(id: species.id, name: newName.trim());
    ref.invalidate(activeSpeciesProvider);
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<CustomSpeciesFormSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CustomSpeciesFormSheet(),
    );
    if (result == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      final speciesId =
          await ref.read(speciesRepositoryProvider).insert(name: result.name);
      for (final catName in result.categoryNames) {
        await ref.read(animalCategoryRepositoryProvider).insert(
              speciesId: speciesId,
              name: catName,
            );
      }
    });
    ref.invalidate(activeSpeciesProvider);
    ref.invalidate(activeCategoriesBySpeciesProvider);
    ref.invalidate(allCategoriesByIdProvider);
    ref.invalidate(categoryLookupProvider);
  }

  Future<void> _restoreTemplate(
    BuildContext context,
    WidgetRef ref,
    List<Species> active,
    List<Species> archived,
  ) async {
    final l = AppLocalizations.of(context)!;
    final present = {
      ...active.map((s) => s.name),
      ...archived.map((s) => s.name),
    };
    final available =
        kSpeciesSeeds.where((s) => !present.contains(s.name)).toList();
    final picked = await showModalBottomSheet<SpeciesSeed?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.speciesManagementRestoreTemplateSheetTitle,
                  style: context.theme.typography.lg,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (available.isEmpty)
                  Text(
                    l.speciesManagementRestoreTemplateEmpty,
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  )
                else
                  for (final seed in available)
                    Material(
                      color: const Color(0x00000000),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(seed.name),
                        subtitle: Text(
                          seed.categories.map((c) => c.name).join(', '),
                        ),
                        onTap: () => Navigator.of(ctx).pop(seed),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      final speciesId =
          await ref.read(speciesRepositoryProvider).insert(name: picked.name);
      for (final cat in picked.categories) {
        await ref.read(animalCategoryRepositoryProvider).insert(
              speciesId: speciesId,
              name: cat.name,
            );
      }
    });
    ref.invalidate(activeSpeciesProvider);
    ref.invalidate(activeCategoriesBySpeciesProvider);
    ref.invalidate(allCategoriesByIdProvider);
    ref.invalidate(categoryLookupProvider);
  }
}

class _SpeciesActiveTile extends StatelessWidget {
  final Species species;
  final List<AnimalCategory> categories;
  final bool canArchive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onArchive;

  const _SpeciesActiveTile({
    required this.species,
    required this.categories,
    required this.canArchive,
    required this.onTap,
    required this.onRename,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final names = categories.map((c) => c.name).join(', ');
    final subtitle = categories.isEmpty
        ? l.speciesManagementCountFmt(0, 0)
        : '${categories.length} — $names';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: AppSizes.listTilePadding,
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: theme.colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.name,
                    style: theme.typography.md.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: const Color(0x00000000),
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l.speciesManagementRename),
                  onTap: () => Navigator.of(ctx).pop('rename'),
                ),
              ),
              Material(
                color: const Color(0x00000000),
                child: ListTile(
                  leading: const Icon(Icons.archive),
                  title: Text(l.speciesManagementArchive),
                  enabled: canArchive,
                  onTap: canArchive
                      ? () => Navigator.of(ctx).pop('archive')
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
    if (action == 'rename') onRename();
    if (action == 'archive') onArchive();
  }
}

class _SpeciesArchivedTile extends StatelessWidget {
  final Species species;
  final VoidCallback onUnarchive;

  const _SpeciesArchivedTile({
    required this.species,
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
              species.name,
              style: theme.typography.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: onUnarchive,
            child: Text(l.speciesManagementUnarchive),
          ),
        ],
      ),
    );
  }
}
