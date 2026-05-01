import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/prestation.dart';
import '../../domain/models/species.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_header.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_stat.dart';

class PrestationCatalogScreen extends ConsumerWidget {
  const PrestationCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activePrestationsProvider);
    final archivedAsync = ref.watch(archivedPrestationsProvider);
    final speciesAsync = ref.watch(activeSpeciesProvider);
    final allCatsAsync = ref.watch(allCategoriesByIdProvider);

    if (activeAsync.isLoading ||
        archivedAsync.isLoading ||
        speciesAsync.isLoading ||
        allCatsAsync.isLoading) {
      return const SafeArea(child: Center(child: FCircularProgress()));
    }
    if (activeAsync.hasError) {
      return SafeArea(child: Text('${activeAsync.error}'));
    }
    if (archivedAsync.hasError) {
      return SafeArea(child: Text('${archivedAsync.error}'));
    }
    if (speciesAsync.hasError) {
      return SafeArea(child: Text('${speciesAsync.error}'));
    }
    if (allCatsAsync.hasError) {
      return SafeArea(child: Text('${allCatsAsync.error}'));
    }

    final active = activeAsync.value!;
    final archived = archivedAsync.value!;
    final species = speciesAsync.value!;
    final allCats = allCatsAsync.value!;

    final subtitle =
        '${active.length} active${active.length == 1 ? '' : 's'} · '
        '${archived.length} archivée${archived.length == 1 ? '' : 's'}';

    // Group active prestations by speciesId (or null for libres).
    final bySpecies = <int, List<Prestation>>{};
    final libres = <Prestation>[];
    for (final p in active) {
      if (p.categoryId == null) {
        libres.add(p);
        continue;
      }
      final cat = allCats[p.categoryId];
      if (cat == null) {
        libres.add(p);
        continue;
      }
      bySpecies.putIfAbsent(cat.speciesId, () => []).add(p);
    }

    return SafeArea(
      child: FScaffold(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: l.prestationCatalogTitle,
                  subtitle: subtitle,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSizes.screenPadding.copyWith(
                      bottom: AppSizes.bottomScrollPadding,
                    ),
                    child: _buildContent(
                      context: context,
                      ref: ref,
                      l: l,
                      active: active,
                      archived: archived,
                      species: species,
                      allCats: allCats,
                      bySpecies: bySpecies,
                      libres: libres,
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
                label: 'Prestation',
                extended: true,
                onPress: () => context.push('/settings/prestations/new'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required List<Prestation> active,
    required List<Prestation> archived,
    required List<Species> species,
    required Map<int, AnimalCategory> allCats,
    required Map<int, List<Prestation>> bySpecies,
    required List<Prestation> libres,
  }) {
    final theme = context.theme;

    if (active.isEmpty && archived.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          l.emptyClientsBody,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in species)
          if ((bySpecies[s.id] ?? const []).isNotEmpty) ...[
            _SectionHeader(title: s.name),
            const SizedBox(height: AppSpacing.sm),
            for (final p in bySpecies[s.id]!)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ActiveTile(
                  prestation: p,
                  subtitleText:
                      '${s.name}/${allCats[p.categoryId]?.name ?? '—'}',
                  onTap: () => context.push('/settings/prestations/${p.id}'),
                  onArchive: () => _archive(ref, p),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        if (libres.isNotEmpty) ...[
          _SectionHeader(title: l.prestationCatalogFreeGroup),
          const SizedBox(height: AppSpacing.sm),
          for (final p in libres)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ActiveTile(
                prestation: p,
                subtitleText: l.prestationCatalogFreeGroup,
                onTap: () => context.push('/settings/prestations/${p.id}'),
                onArchive: () => _archive(ref, p),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (archived.isNotEmpty)
          _ArchivedSection(
            archived: archived,
            allCats: allCats,
            species: species,
            onUnarchive: (p) => _unarchive(ref, p),
          ),
      ],
    );
  }

  Future<void> _archive(WidgetRef ref, Prestation p) async {
    await ref.read(prestationRepositoryProvider).archive(p.id);
    ref.invalidate(activePrestationsProvider);
    ref.invalidate(archivedPrestationsProvider);
    ref.invalidate(prestationCountActiveProvider);
  }

  Future<void> _unarchive(WidgetRef ref, Prestation p) async {
    await ref.read(prestationRepositoryProvider).unarchive(p.id);
    ref.invalidate(activePrestationsProvider);
    ref.invalidate(archivedPrestationsProvider);
    ref.invalidate(prestationCountActiveProvider);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      title,
      style: theme.typography.lg.copyWith(
        color: theme.colors.foreground,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  final Prestation prestation;
  final String subtitleText;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _ActiveTile({
    required this.prestation,
    required this.subtitleText,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final p = prestation;

    final stats = <Widget>[];
    if (p.priceCents != null) stats.add(AppStat(value: formatEuros(p.priceCents!)));
    if (p.minutes != null) stats.add(AppStat(value: '${p.minutes} min'));

    return AppListTile(
      variant: stats.isEmpty ? AppListTileVariant.standard : AppListTileVariant.rich,
      title: p.name,
      subtitle: subtitleText,
      metadata: stats.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  stats[i],
                ],
              ],
            ),
      suffix: Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
      onTap: onTap,
      onLongPress: onArchive,
    );
  }
}

class _ArchivedSection extends StatefulWidget {
  final List<Prestation> archived;
  final Map<int, AnimalCategory> allCats;
  final List<Species> species;
  final void Function(Prestation) onUnarchive;

  const _ArchivedSection({
    required this.archived,
    required this.allCats,
    required this.species,
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

    // Build speciesName lookup for subtitle
    final speciesById = {for (final s in widget.species) s.id: s.name};

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
                  l.prestationCatalogArchivedSection,
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
          for (final p in widget.archived)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ArchivedTile(
                prestation: p,
                subtitleText: _subtitleFor(p, widget.allCats, speciesById, l),
                onUnarchive: () => widget.onUnarchive(p),
              ),
            ),
        ],
      ],
    );
  }

  String _subtitleFor(
    Prestation p,
    Map<int, AnimalCategory> allCats,
    Map<int, String> speciesById,
    AppLocalizations l,
  ) {
    if (p.categoryId == null) return l.prestationCatalogFreeGroup;
    final cat = allCats[p.categoryId];
    if (cat == null) return l.prestationCatalogFreeGroup;
    final sp = speciesById[cat.speciesId] ?? '—';
    return '$sp/${cat.name}';
  }
}

class _ArchivedTile extends StatelessWidget {
  final Prestation prestation;
  final String subtitleText;
  final VoidCallback onUnarchive;

  const _ArchivedTile({
    required this.prestation,
    required this.subtitleText,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = prestation;

    final stats = <Widget>[];
    if (p.priceCents != null) stats.add(AppStat(value: formatEuros(p.priceCents!)));
    if (p.minutes != null) stats.add(AppStat(value: '${p.minutes} min'));

    return AppListTile(
      variant: stats.isEmpty ? AppListTileVariant.standard : AppListTileVariant.rich,
      title: p.name,
      subtitle: subtitleText,
      metadata: stats.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  stats[i],
                ],
              ],
            ),
      suffix: FButton(
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        onPress: onUnarchive,
        child: Text(l.speciesManagementUnarchive),
      ),
    );
  }
}
