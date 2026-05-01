import 'package:flutter/material.dart'
    show ListTile, Material, Icons, IconButton, showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/prestation.dart';
import '../../domain/models/species.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

class PrestationCatalogScreen extends ConsumerWidget {
  const PrestationCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activePrestationsProvider);
    final archivedAsync = ref.watch(archivedPrestationsProvider);
    final speciesAsync = ref.watch(activeSpeciesProvider);
    final allCatsAsync = ref.watch(allCategoriesByIdProvider);
    final theme = context.theme;

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.prestationCatalogTitle)),
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: _buildBody(
            context: context,
            ref: ref,
            l: l,
            theme: theme,
            activeAsync: activeAsync,
            archivedAsync: archivedAsync,
            speciesAsync: speciesAsync,
            allCatsAsync: allCatsAsync,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required FThemeData theme,
    required AsyncValue<List<Prestation>> activeAsync,
    required AsyncValue<List<Prestation>> archivedAsync,
    required AsyncValue<List<Species>> speciesAsync,
    required AsyncValue<Map<int, AnimalCategory>> allCatsAsync,
  }) {
    if (activeAsync.isLoading ||
        archivedAsync.isLoading ||
        speciesAsync.isLoading ||
        allCatsAsync.isLoading) {
      return const Center(child: FCircularProgress());
    }
    if (activeAsync.hasError) return Text('${activeAsync.error}');
    if (archivedAsync.hasError) return Text('${archivedAsync.error}');
    if (speciesAsync.hasError) return Text('${speciesAsync.error}');
    if (allCatsAsync.hasError) return Text('${allCatsAsync.error}');

    final active = activeAsync.value!;
    final archived = archivedAsync.value!;
    final species = speciesAsync.value!;
    final allCats = allCatsAsync.value!;

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
        // Orphan reference — drop into libres so it's still visible.
        libres.add(p);
        continue;
      }
      bySpecies.putIfAbsent(cat.speciesId, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l.emptyClientsBody, // generic fallback; dedicated key intentionally avoided
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          for (final s in species)
            if ((bySpecies[s.id] ?? const []).isNotEmpty)
              _SpeciesGroup(
                title: s.name,
                prestations: bySpecies[s.id]!,
                allCats: allCats,
                onTap: (p) => context.push('/settings/prestations/${p.id}'),
                onArchive: (p) => _archive(ref, p),
              ),
          if (libres.isNotEmpty)
            _SpeciesGroup(
              title: l.prestationCatalogFreeGroup,
              prestations: libres,
              allCats: allCats,
              onTap: (p) => context.push('/settings/prestations/${p.id}'),
              onArchive: (p) => _archive(ref, p),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        FButton(
          onPress: () => context.push('/settings/prestations/new'),
          child: Text(l.prestationCatalogAddCta),
        ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ArchivedSection(
            archived: archived,
            allCats: allCats,
            onUnarchive: (p) => _unarchive(ref, p),
          ),
        ],
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

class _SpeciesGroup extends StatelessWidget {
  final String title;
  final List<Prestation> prestations;
  final Map<int, AnimalCategory> allCats;
  final void Function(Prestation) onTap;
  final void Function(Prestation) onArchive;

  const _SpeciesGroup({
    required this.title,
    required this.prestations,
    required this.allCats,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.typography.lg.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final p in prestations)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PrestationActiveTile(
                prestation: p,
                category: p.categoryId == null ? null : allCats[p.categoryId],
                onTap: () => onTap(p),
                onArchive: () => onArchive(p),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArchivedSection extends StatefulWidget {
  final List<Prestation> archived;
  final Map<int, AnimalCategory> allCats;
  final void Function(Prestation) onUnarchive;

  const _ArchivedSection({
    required this.archived,
    required this.allCats,
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
                  l.prestationCatalogArchivedSection,
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
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
              child: _PrestationArchivedTile(
                prestation: p,
                category:
                    p.categoryId == null ? null : widget.allCats[p.categoryId],
                onUnarchive: () => widget.onUnarchive(p),
              ),
            ),
        ],
      ],
    );
  }
}

String _formatSubtitle({
  required Prestation p,
  required AnimalCategory? category,
}) {
  final priceStr = p.priceCents == null
      ? '—'
      : '${(p.priceCents! / 100).toStringAsFixed(2)} €';
  final minutesStr = p.minutes == null ? '—' : '${p.minutes} min';
  if (p.categoryId == null) {
    return '$priceStr · $minutesStr';
  }
  final catLabel = category?.name ?? '—';
  return '$catLabel · $priceStr · $minutesStr';
}

class _PrestationActiveTile extends StatelessWidget {
  final Prestation prestation;
  final AnimalCategory? category;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _PrestationActiveTile({
    required this.prestation,
    required this.category,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final subtitle = _formatSubtitle(p: prestation, category: category);

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
                    prestation.name,
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
                  title: Text(l.clientDetailEdit),
                  onTap: () => Navigator.of(ctx).pop('edit'),
                ),
              ),
              Material(
                color: const Color(0x00000000),
                child: ListTile(
                  leading: const Icon(Icons.archive),
                  title: Text(l.speciesManagementArchive),
                  onTap: () => Navigator.of(ctx).pop('archive'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (action == 'edit') onTap();
    if (action == 'archive') onArchive();
  }
}

class _PrestationArchivedTile extends StatelessWidget {
  final Prestation prestation;
  final AnimalCategory? category;
  final VoidCallback onUnarchive;

  const _PrestationArchivedTile({
    required this.prestation,
    required this.category,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final subtitle = _formatSubtitle(p: prestation, category: category);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prestation.name,
                  style: theme.typography.md.copyWith(
                    color: theme.colors.mutedForeground,
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
