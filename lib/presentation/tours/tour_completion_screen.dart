import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/prestation.dart';
import '../../domain/models/species.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart'
    show clientsAsyncProvider, clientNotesMapProvider;
import '../widgets/app_action_bar.dart';
import '../widgets/app_diff_row.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import 'tours_list_screen.dart' show toursAsyncProvider;

final _tourForCompletionProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});

class TourCompletionScreen extends ConsumerStatefulWidget {
  final int tourId;
  const TourCompletionScreen({super.key, required this.tourId});

  @override
  ConsumerState<TourCompletionScreen> createState() =>
      _TourCompletionScreenState();
}

class _TourCompletionScreenState extends ConsumerState<TourCompletionScreen> {
  /// Per-stop draft state, keyed by stop.id.
  final Map<int, _StopDraft> _drafts = {};
  bool _initialised = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final d in _drafts.values) {
      d.dispose();
    }
    super.dispose();
  }

  void _ensureDrafts(TourWithStops bundle) {
    if (_initialised) return;
    for (final s in bundle.stops) {
      if (s.clientId == null) continue;
      _drafts[s.id] = _StopDraft.fromPlanned(s.plannedPrestations);
    }
    _initialised = true;
  }

  Future<void> _addOffPlan(int stopId) async {
    final draft = _drafts[stopId]!;
    final active = ref.read(activePrestationsProvider).value ?? const [];
    final inUseIds = draft.rows.map((r) => r.prestationId).toSet();
    final candidates = [
      for (final p in active)
        if (!inUseIds.contains(p.id)) p,
    ];
    final cats = ref.read(allCategoriesByIdProvider).value ??
        const <int, AnimalCategory>{};
    final speciesList = ref.read(activeSpeciesProvider).value ?? const [];
    final speciesById = {for (final s in speciesList) s.id: s};

    final picked = await showFSheet<Prestation>(
      context: context,
      side: FLayout.btt,
      builder: (sheetCtx) => _OffPlanPickerSheet(
        candidates: candidates,
        catsById: cats,
        speciesById: speciesById,
      ),
    );
    if (picked == null) return;
    final cat = picked.categoryId == null ? null : cats[picked.categoryId];
    final spec = cat == null ? null : speciesById[cat.speciesId];
    setState(() {
      draft.addRow(_StopRow(
        prestationId: picked.id,
        nameSnapshot: picked.name,
        priceCentsSnapshot: picked.priceCents ?? 0,
        minutesSnapshot: picked.minutes ?? 0,
        categoryIdSnapshot: cat?.id,
        categoryNameSnapshot: cat?.name,
        speciesNameSnapshot: spec?.name,
        qty: 1,
        checked: true,
      ));
    });
  }

  ({int minutes, int revenueCents}) _liveTotals() {
    var minutes = 0;
    var revenue = 0;
    for (final draft in _drafts.values) {
      for (final r in draft.rows) {
        if (!r.checked) continue;
        final q = r.qty;
        if (q <= 0) continue;
        minutes += q * r.minutesSnapshot;
        revenue += q * r.priceCentsSnapshot;
      }
    }
    return (minutes: minutes, revenueCents: revenue);
  }

  Future<void> _confirm(TourWithStops bundle) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);

    // Re-snapshot from current active list at save time. If a prestation no
    // longer exists in active (deleted/archived), preserve the row's existing
    // snapshot fields.
    final active = ref.read(activePrestationsProvider).value ?? const [];
    final activeById = {for (final p in active) p.id: p};
    final cats = ref.read(allCategoriesByIdProvider).value ??
        const <int, AnimalCategory>{};
    final speciesList = ref.read(activeSpeciesProvider).value ?? const [];
    final speciesById = {for (final s in speciesList) s.id: s};

    final actuals =
        <int, ({List<TourStopPrestation> actuals, String? note})>{};
    for (final entry in _drafts.entries) {
      final draft = entry.value;
      final note = draft.noteCtrl.text.trim();
      final list = <TourStopPrestation>[];
      for (final r in draft.rows) {
        if (!r.checked) continue;
        if (r.qty <= 0) continue;
        final p = activeById[r.prestationId];
        if (p != null) {
          // Re-snapshot from current Prestation record.
          final cat = p.categoryId == null ? null : cats[p.categoryId];
          final spec = cat == null ? null : speciesById[cat.speciesId];
          list.add(TourStopPrestation(
            prestationId: p.id,
            qty: r.qty,
            nameSnapshot: p.name,
            priceCentsSnapshot: p.priceCents ?? 0,
            minutesSnapshot: p.minutes ?? 0,
            categoryIdSnapshot: cat?.id,
            categoryNameSnapshot: cat?.name,
            speciesNameSnapshot: spec?.name,
          ));
        } else {
          // Prestation missing from active list; keep existing snapshot.
          list.add(TourStopPrestation(
            prestationId: r.prestationId,
            qty: r.qty,
            nameSnapshot: r.nameSnapshot,
            priceCentsSnapshot: r.priceCentsSnapshot,
            minutesSnapshot: r.minutesSnapshot,
            categoryIdSnapshot: r.categoryIdSnapshot,
            categoryNameSnapshot: r.categoryNameSnapshot,
            speciesNameSnapshot: r.speciesNameSnapshot,
          ));
        }
      }
      actuals[entry.key] = (
        actuals: list,
        note: note.isEmpty ? null : note,
      );
    }
    await ref.read(tourRepositoryProvider).markCompleted(widget.tourId, actuals);

    // Invalidate downstream caches.
    ref.invalidate(_tourForCompletionProvider(widget.tourId));
    ref.invalidate(tourByIdProvider(widget.tourId));
    ref.invalidate(clientsAsyncProvider);
    ref.invalidate(clientNotesMapProvider);
    ref.invalidate(toursAsyncProvider);

    if (!mounted) return;
    setState(() => _saving = false);
    showFToast(context: context, title: Text(l.tourCompletionConfirm));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(_tourForCompletionProvider(widget.tourId));

    return FScaffold(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            _ensureDrafts(bundle);
            final visibleStops =
                bundle.stops.where((s) => s.clientId != null).toList();
            final totals = _liveTotals();
            final feeCents = bundle.tour.totalTravelFeeCents;
            final plannedRevenue = bundle.stops.fold<int>(
                0,
                (s, st) =>
                    s +
                    st.plannedPrestations.fold<int>(
                        0, (a, p) => a + p.priceCentsSnapshot * p.qty));
            final actualRevenue = totals.revenueCents + feeCents;
            final delta = actualRevenue - plannedRevenue - feeCents;
            final stopsValidated = _drafts.values
                .where((d) => d.rows.any((r) => r.checked && r.qty > 0))
                .length;

            final deltaSign =
                delta == 0 ? '' : (delta > 0 ? '+' : '-');
            final deltaLabel = '$deltaSign${formatEuros(delta.abs())}';

            return Column(
              children: [
                AppHeader(
                  title: l.tourCompletionTitle,
                  subtitle:
                      '${visibleStops.length} stops · prévu ${formatEuros(plannedRevenue + feeCents)}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: AppKpiRow(
                    cells: [
                      AppKpiCell(
                        value: '$stopsValidated/${visibleStops.length}',
                        label: l.kpiLabelStops,
                      ),
                      AppKpiCell(
                        value: formatEuros(actualRevenue),
                        label: l.kpiLabelRevenue,
                        valueColor: theme.colors.secondary,
                      ),
                      AppKpiCell(
                        value: formatDuration(totals.minutes),
                        label: l.kpiLabelDuration,
                      ),
                      AppKpiCell(
                        value: delta == 0 ? '0 €' : deltaLabel,
                        label: l.kpiLabelDeltaVsPlanned,
                        valueColor: delta == 0
                            ? theme.colors.mutedForeground
                            : (delta > 0
                                ? theme.colors.primary
                                : theme.colors.destructive),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    padding: AppSizes.screenPadding,
                    itemCount: visibleStops.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final s = visibleStops[i];
                      final draft = _drafts[s.id]!;
                      final stopMin = draft.rows.fold<int>(
                          0,
                          (acc, r) =>
                              acc +
                              (r.checked && r.qty > 0
                                  ? r.qty * r.minutesSnapshot
                                  : 0));
                      final stopRev = draft.rows.fold<int>(
                          0,
                          (acc, r) =>
                              acc +
                              (r.checked && r.qty > 0
                                  ? r.qty * r.priceCentsSnapshot
                                  : 0));
                      final plannedById = {
                        for (final p in s.plannedPrestations)
                          p.prestationId: p.qty,
                      };
                      return AppSectionCard(
                        icon: FIcons.user,
                        title: '${i + 1} · ${s.clientNameSnapshot}',
                        trailing: Text(
                          '${formatEuros(stopRev)} · ${formatDuration(stopMin)}',
                          style: tabularStyle(theme.typography.sm).copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var ri = 0; ri < draft.rows.length; ri++)
                              _PrestationRowEditor(
                                row: draft.rows[ri],
                                planned: plannedById[
                                        draft.rows[ri].prestationId] ??
                                    0,
                                onCheckedChanged: (v) =>
                                    setState(() => draft.rows[ri].checked = v),
                                onQtyChanged: (q) =>
                                    setState(() => draft.rows[ri].qty = q),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FButton(
                                variant: FButtonVariant.outline,
                                onPress: () => _addOffPlan(s.id),
                                child: Text(l.tourCompletionAddOffPlan),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: draft.noteCtrl,
                              ),
                              label: Text(l.tourCompletionNoteHint),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                AppActionBar(
                  primary: AppPrimaryButton(
                    label: l.tourCompletionConfirm,
                    loading: _saving,
                    onPress: _saving
                        ? null
                        : () async {
                            final ok = await showDestructiveConfirm(
                              context,
                              title: l.tourCompletionConfirmTitle,
                              body: l.tourCompletionConfirmBody,
                              cancelLabel: l.commonCancel,
                              confirmLabel: 'Valider',
                            );
                            if (ok && context.mounted) {
                              await _confirm(bundle);
                            }
                          },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StopDraft {
  final List<_StopRow> rows;
  final TextEditingController noteCtrl;

  _StopDraft._(this.rows, this.noteCtrl);

  factory _StopDraft.fromPlanned(List<TourStopPrestation> planned) {
    return _StopDraft._(
      [
        for (final p in planned)
          _StopRow(
            prestationId: p.prestationId,
            nameSnapshot: p.nameSnapshot,
            priceCentsSnapshot: p.priceCentsSnapshot,
            minutesSnapshot: p.minutesSnapshot,
            categoryIdSnapshot: p.categoryIdSnapshot,
            categoryNameSnapshot: p.categoryNameSnapshot,
            speciesNameSnapshot: p.speciesNameSnapshot,
            qty: p.qty,
            checked: true,
          ),
      ],
      TextEditingController(),
    );
  }

  void addRow(_StopRow row) => rows.add(row);

  void dispose() {
    noteCtrl.dispose();
    for (final r in rows) {
      r.qtyCtrl.dispose();
    }
  }
}

class _StopRow {
  final int prestationId;
  final String nameSnapshot;
  final int priceCentsSnapshot;
  final int minutesSnapshot;
  final int? categoryIdSnapshot;
  final String? categoryNameSnapshot;
  final String? speciesNameSnapshot;
  bool checked;
  int qty;
  final TextEditingController qtyCtrl;

  _StopRow({
    required this.prestationId,
    required this.nameSnapshot,
    required this.priceCentsSnapshot,
    required this.minutesSnapshot,
    required this.categoryIdSnapshot,
    required this.categoryNameSnapshot,
    required this.speciesNameSnapshot,
    required this.qty,
    required this.checked,
  }) : qtyCtrl = TextEditingController(text: '$qty');
}

class _PrestationRowEditor extends StatelessWidget {
  final _StopRow row;
  final int planned;
  final ValueChanged<bool> onCheckedChanged;
  final ValueChanged<int> onQtyChanged;

  const _PrestationRowEditor({
    required this.row,
    required this.planned,
    required this.onCheckedChanged,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final priceLabel = row.priceCentsSnapshot == 0
        ? null
        : formatEuros(row.priceCentsSnapshot * (row.checked ? row.qty : 0));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCheckedChanged(!row.checked),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: row.checked ? theme.colors.primary : null,
                border: row.checked
                    ? null
                    : Border.all(color: theme.colors.border, width: 1.5),
              ),
              child: row.checked
                  ? Icon(FIcons.check,
                      color: theme.colors.primaryForeground, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppDiffRow(
              label: row.nameSnapshot,
              planned: planned,
              actual: row.checked ? row.qty : 0,
              amountLabel: priceLabel,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 56,
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: row.qtyCtrl,
                onChange: (v) {
                  final q = int.tryParse(v.text) ?? 0;
                  onQtyChanged(q);
                },
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }
}

class _OffPlanPickerSheet extends StatelessWidget {
  final List<Prestation> candidates;
  final Map<int, AnimalCategory> catsById;
  final Map<int, Species> speciesById;

  const _OffPlanPickerSheet({
    required this.candidates,
    required this.catsById,
    required this.speciesById,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return ColoredBox(
      color: theme.colors.background,
      child: SafeArea(
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
                l.tourCompletionAddOffPlan,
                style:
                    theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                itemCount: candidates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final p = candidates[i];
                  final cat =
                      p.categoryId == null ? null : catsById[p.categoryId];
                  final spec =
                      cat == null ? null : speciesById[cat.speciesId];
                  final subtitleParts = <String>[];
                  if (cat != null) {
                    subtitleParts.add('${spec?.name ?? '?'}/${cat.name}');
                  }
                  final priceText = p.priceCents == null
                      ? '—'
                      : '${(p.priceCents! / 100).toStringAsFixed(2)} €/u';
                  final minText =
                      p.minutes == null ? '— min/u' : '${p.minutes} min/u';
                  subtitleParts.add('$priceText · $minText');

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(p),
                    child: Container(
                      padding: AppSizes.listTilePadding,
                      decoration: BoxDecoration(
                        color: theme.colors.card,
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(color: theme.colors.border),
                      ),
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
                        ],
                      ),
                    ),
                  );
                },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
