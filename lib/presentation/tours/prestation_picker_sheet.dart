import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/prestation.dart';
import '../../domain/models/species.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

/// Modal sheet for picking prestations at a tour stop.
///
/// Splits active prestations into "Suggested" (those whose category matches an
/// animal category present at the client with count > 0) and "Other". On open,
/// suggested prestations are pre-selected with qty = client's animal count for
/// that category. On validate, returns a list of [TourStopPrestation] with
/// snapshots resolved from the catalog at this moment.
///
/// Returns `null` if the user cancels.
Future<List<TourStopPrestation>?> showPrestationPickerSheet(
  BuildContext context, {
  required String clientName,
  required List<AnimalCount> clientAnimals,
  List<TourStopPrestation> initialSelection = const [],
}) {
  return showFSheet<List<TourStopPrestation>?>(
    context: context,
    side: FLayout.btt,
    builder: (sheetCtx) => PrestationPickerSheet(
      clientName: clientName,
      clientAnimals: clientAnimals,
      initialSelection: initialSelection,
    ),
  );
}

class PrestationPickerSheet extends ConsumerStatefulWidget {
  final String clientName;
  final List<AnimalCount> clientAnimals;
  final List<TourStopPrestation> initialSelection;

  const PrestationPickerSheet({
    super.key,
    required this.clientName,
    required this.clientAnimals,
    this.initialSelection = const [],
  });

  @override
  ConsumerState<PrestationPickerSheet> createState() =>
      _PrestationPickerSheetState();
}

class _PrestationPickerSheetState extends ConsumerState<PrestationPickerSheet> {
  // State per prestationId : selected (bool) + qty (int).
  final Map<int, bool> _selected = {};
  final Map<int, int> _qty = {};
  // Tracks which prestation IDs we've already initialized (from
  // initialSelection or as suggested defaults), so subsequent rebuilds don't
  // clobber the user's edits.
  final Set<int> _initialized = {};

  @override
  void initState() {
    super.initState();
    for (final s in widget.initialSelection) {
      _selected[s.prestationId] = true;
      _qty[s.prestationId] = s.qty;
      _initialized.add(s.prestationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final activeAsync = ref.watch(activePrestationsProvider);
    final allCatsAsync = ref.watch(allCategoriesByIdProvider);
    final speciesAsync = ref.watch(activeSpeciesProvider);

    return ColoredBox(
      color: theme.colors.background,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: activeAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: FCircularProgress()),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(child: Text('$e')),
          ),
          data: (active) {
            // Determine "client cats with count > 0".
            final clientCats = <int>{
              for (final a in widget.clientAnimals)
                if (a.count > 0) a.categoryId,
            };

            // Partition prestations into suggested vs other.
            final suggested = <Prestation>[];
            final other = <Prestation>[];
            for (final p in active) {
              final cid = p.categoryId;
              if (cid != null && clientCats.contains(cid)) {
                suggested.add(p);
              } else {
                other.add(p);
              }
            }

            // For each suggested prestation, set sensible defaults if not
            // already initialized.
            for (final p in suggested) {
              if (_initialized.contains(p.id)) continue;
              _initialized.add(p.id);
              _selected[p.id] = true;
              final cnt = widget.clientAnimals
                  .firstWhere(
                    (a) => a.categoryId == p.categoryId,
                    orElse: () =>
                        const AnimalCount(categoryId: 0, count: 0),
                  )
                  .count;
              _qty[p.id] = cnt;
            }

            final speciesById = <int, Species>{
              for (final s in (speciesAsync.value ?? const <Species>[]))
                s.id: s,
            };
            final catsById =
                allCatsAsync.value ?? const <int, AnimalCategory>{};

            return _buildBody(
              context: context,
              l: l,
              theme: theme,
              suggested: suggested,
              other: other,
              speciesById: speciesById,
              catsById: catsById,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AppLocalizations l,
    required FThemeData theme,
    required List<Prestation> suggested,
    required List<Prestation> other,
    required Map<int, Species> speciesById,
    required Map<int, AnimalCategory> catsById,
  }) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              l.prestationPickerTitleFmt(widget.clientName),
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                if (suggested.isNotEmpty)
                  _section(
                    title: l.prestationPickerSuggested,
                    list: suggested,
                    speciesById: speciesById,
                    catsById: catsById,
                    theme: theme,
                    l: l,
                  ),
                if (other.isNotEmpty)
                  _section(
                    title: l.prestationPickerOther,
                    list: other,
                    speciesById: speciesById,
                    catsById: catsById,
                    theme: theme,
                    l: l,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(context).pop(null),
                  child: Text(l.prestationPickerCancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FButton(
                  onPress: _onValidate,
                  child: Text(l.prestationPickerValidate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Prestation> list,
    required Map<int, Species> speciesById,
    required Map<int, AnimalCategory> catsById,
    required FThemeData theme,
    required AppLocalizations l,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            title,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        for (final p in list)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PrestationRow(
              prestation: p,
              speciesById: speciesById,
              catsById: catsById,
              isSelected: _selected[p.id] ?? false,
              qty: _qty[p.id] ?? 0,
              onSelectedChanged: (v) =>
                  setState(() => _selected[p.id] = v),
              onQtyChanged: (q) => setState(() => _qty[p.id] = q),
            ),
          ),
      ],
    );
  }

  Future<void> _onValidate() async {
    final active = ref.read(activePrestationsProvider).value ?? const [];
    final cats = ref.read(allCategoriesByIdProvider).value ??
        const <int, AnimalCategory>{};
    final speciesList = ref.read(activeSpeciesProvider).value ?? const [];
    final speciesById = {for (final s in speciesList) s.id: s};

    final result = <TourStopPrestation>[];
    for (final p in active) {
      final sel = _selected[p.id] ?? false;
      if (!sel) continue;
      final q = _qty[p.id] ?? 0;
      if (q <= 0) continue;
      final cat = p.categoryId == null ? null : cats[p.categoryId];
      final spec = cat == null ? null : speciesById[cat.speciesId];
      result.add(TourStopPrestation(
        prestationId: p.id,
        qty: q,
        nameSnapshot: p.name,
        priceCentsSnapshot: p.priceCents ?? 0,
        minutesSnapshot: p.minutes ?? 0,
        categoryIdSnapshot: cat?.id,
        categoryNameSnapshot: cat?.name,
        speciesNameSnapshot: spec?.name,
      ));
    }
    if (mounted) Navigator.of(context).pop(result);
  }
}

class _PrestationRow extends StatefulWidget {
  final Prestation prestation;
  final Map<int, Species> speciesById;
  final Map<int, AnimalCategory> catsById;
  final bool isSelected;
  final int qty;
  final ValueChanged<bool> onSelectedChanged;
  final ValueChanged<int> onQtyChanged;

  const _PrestationRow({
    required this.prestation,
    required this.speciesById,
    required this.catsById,
    required this.isSelected,
    required this.qty,
    required this.onSelectedChanged,
    required this.onQtyChanged,
  });

  @override
  State<_PrestationRow> createState() => _PrestationRowState();
}

class _PrestationRowState extends State<_PrestationRow> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.qty}');
  }

  @override
  void didUpdateWidget(covariant _PrestationRow old) {
    super.didUpdateWidget(old);
    final newText = '${widget.qty}';
    if (_qtyController.text != newText) {
      _qtyController.text = newText;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestation;
    final cat = p.categoryId == null ? null : widget.catsById[p.categoryId];
    final spec = cat == null ? null : widget.speciesById[cat.speciesId];
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    final subtitleParts = <String>[];
    if (cat != null) {
      subtitleParts.add('${spec?.name ?? '?'}/${cat.name}');
    }
    final priceText = p.priceCents == null
        ? '—'
        : '${(p.priceCents! / 100).toStringAsFixed(2)} €/u';
    final minText = p.minutes == null ? '— min/u' : '${p.minutes} min/u';
    subtitleParts.add('$priceText · $minText');

    return Container(
      padding: AppSizes.listTilePadding,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelectedChanged(!widget.isSelected),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: theme.typography.md.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitleParts.join(' · '),
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      if (p.priceCents == null && p.minutes == null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(
                            l.prestationPickerEmptyValues,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected ? theme.colors.primary : null,
                    border: widget.isSelected
                        ? null
                        : Border.all(color: theme.colors.border, width: 2),
                  ),
                  child: widget.isSelected
                      ? Icon(
                          FIcons.check,
                          color: theme.colors.primaryForeground,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (widget.isSelected)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    '×',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 96,
                    child: FTextField(
                      control: FTextFieldControl.managed(
                        controller: _qtyController,
                        onChange: (v) {
                          final q = int.tryParse(v.text) ?? 0;
                          widget.onQtyChanged(q);
                        },
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
