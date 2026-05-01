import 'package:flutter/material.dart'
    show
        TextField,
        InputDecoration,
        Material,
        Icons,
        ListTile,
        showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/animal_icons.dart';
import '../../core/design_tokens.dart';
import '../../data/seeds/species_seeds.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/species.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../onboarding/custom_species_form_sheet.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_header.dart';
import '../widgets/app_list_tile.dart';

class SpeciesManagementScreen extends ConsumerWidget {
  const SpeciesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activeSpeciesProvider);
    final archivedAsync = ref.watch(archivedSpeciesProvider);
    final catsAsync = ref.watch(activeCategoriesBySpeciesProvider);

    if (activeAsync.isLoading || archivedAsync.isLoading) {
      return const SafeArea(child: Center(child: FCircularProgress()));
    }
    if (activeAsync.hasError) {
      return SafeArea(child: Text('${activeAsync.error}'));
    }
    if (archivedAsync.hasError) {
      return SafeArea(child: Text('${archivedAsync.error}'));
    }

    final active = activeAsync.value!;
    final archived = archivedAsync.value!;
    final catsBySpecies =
        catsAsync.hasValue ? catsAsync.value! : const <int, List<AnimalCategory>>{};

    final subtitle =
        '${active.length} active${active.length == 1 ? '' : 's'} · '
        '${archived.length} archivée${archived.length == 1 ? '' : 's'}';

    return SafeArea(
      child: FScaffold(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: l.speciesManagementTitle,
                  subtitle: subtitle,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSizes.screenPadding.copyWith(
                      bottom: AppSizes.bottomScrollPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final species in active)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppListTile(
                              variant: AppListTileVariant.standard,
                              prefix: _speciesPrefix(species),
                              title: species.name,
                              subtitle: _categoriesSubtitle(
                                catsBySpecies[species.id] ?? const [],
                                l,
                              ),
                              suffix: Icon(
                                FIcons.chevronRight,
                                color: context.theme.colors.mutedForeground,
                              ),
                              onTap: () => context
                                  .push('/settings/species/${species.id}'),
                              onLongPress: () =>
                                  _openTileMenu(context, ref, species, active),
                            ),
                          ),
                        if (archived.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ArchivedSection(
                            archived: archived,
                            onUnarchive: (species) async {
                              await ref
                                  .read(speciesRepositoryProvider)
                                  .unarchive(species.id);
                              ref.invalidate(activeSpeciesProvider);
                              ref.invalidate(archivedSpeciesProvider);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: AppFAB(
                icon: FIcons.plus,
                label: 'Espèce',
                extended: true,
                onPress: () => _showAddSheet(
                  context,
                  ref,
                  active,
                  archived,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _speciesPrefix(Species species) {
    final asset = iconAssetForSpeciesKey(species.iconKey);
    if (asset == null) return null;
    return SvgPicture.asset(asset, width: 24, height: 24);
  }

  String _categoriesSubtitle(List<AnimalCategory> cats, AppLocalizations l) {
    if (cats.isEmpty) return l.speciesManagementCountFmt(0, 0);
    return '${cats.length} catégorie${cats.length == 1 ? '' : 's'}';
  }

  Future<void> _openTileMenu(
    BuildContext context,
    WidgetRef ref,
    Species species,
    List<Species> active,
  ) async {
    final l = AppLocalizations.of(context)!;
    final canArchive = active.length > 1;
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
    if (action == 'rename') {
      if (context.mounted) await _renameSpecies(context, ref, species);
    }
    if (action == 'archive') {
      await ref.read(speciesRepositoryProvider).archive(species.id);
      ref.invalidate(activeSpeciesProvider);
      ref.invalidate(archivedSpeciesProvider);
    }
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

  Future<void> _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    List<Species> active,
    List<Species> archived,
  ) async {
    final l = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FButton(
                  onPress: () => Navigator.of(ctx).pop('custom'),
                  child: Text(l.speciesManagementAddSpecies),
                ),
                const SizedBox(height: AppSpacing.sm),
                FButton(
                  variant: FButtonVariant.ghost,
                  onPress: () => Navigator.of(ctx).pop('template'),
                  child: Text(l.speciesManagementRestoreTemplate),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == 'custom') {
      if (context.mounted) await _addCustom(context, ref);
    }
    if (action == 'template') {
      if (context.mounted) await _restoreTemplate(context, ref, active, archived);
    }
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
    ref.invalidate(categoryDisplayInfoProvider);
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
    final prestationRepo = ref.read(prestationRepositoryProvider);
    await db.transaction(() async {
      final speciesId =
          await ref.read(speciesRepositoryProvider).insert(name: picked.name);
      for (final cat in picked.categories) {
        final catId = await ref.read(animalCategoryRepositoryProvider).insert(
              speciesId: speciesId,
              name: cat.name,
            );
        if (cat.defaultPrestationName != null) {
          await prestationRepo.insert(
            name: cat.defaultPrestationName!,
            priceCents: null,
            minutes: null,
            categoryId: catId,
          );
        }
      }
    });
    ref.invalidate(activeSpeciesProvider);
    ref.invalidate(activeCategoriesBySpeciesProvider);
    ref.invalidate(allCategoriesByIdProvider);
    ref.invalidate(categoryDisplayInfoProvider);
    ref.invalidate(activePrestationsProvider);
    ref.invalidate(prestationCountActiveProvider);
  }
}

class _ArchivedSection extends StatefulWidget {
  final List<Species> archived;
  final void Function(Species) onUnarchive;

  const _ArchivedSection({
    required this.archived,
    required this.onUnarchive,
  });

  @override
  State<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _ArchivedSectionState extends State<_ArchivedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.speciesManagementArchivedSection,
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _expanded ? FIcons.chevronUp : FIcons.chevronDown,
                color: theme.colors.mutedForeground,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final species in widget.archived)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppListTile(
                variant: AppListTileVariant.compact,
                title: species.name,
                suffix: FButton(
                  variant: FButtonVariant.outline,
                  size: FButtonSizeVariant.sm,
                  onPress: () => widget.onUnarchive(species),
                  child: Text(l.speciesManagementUnarchive),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
