import 'package:flutter/material.dart' show Locale, showDatePicker;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/manual_history_entry.dart';
import '../../domain/models/prestation.dart';
import '../../domain/models/species.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart'
    show clientsAsyncProvider, clientNotesMapProvider;

Future<void> showManualHistoryEntrySheet(
  BuildContext context, {
  required int clientId,
  ManualHistoryEntry? existing,
}) {
  return showFSheet<void>(
    context: context,
    side: FLayout.btt,
    builder: (sheetCtx) => _Sheet(clientId: clientId, existing: existing),
  );
}

class _Sheet extends ConsumerStatefulWidget {
  final int clientId;
  final ManualHistoryEntry? existing;
  const _Sheet({required this.clientId, this.existing});

  @override
  ConsumerState<_Sheet> createState() => _SheetState();
}

class _SheetState extends ConsumerState<_Sheet> {
  late DateTime? _date = widget.existing?.date;
  late final List<_Row> _rows = [
    for (final p in widget.existing?.prestations ?? const <TourStopPrestation>[])
      _Row(
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
  ];
  late final TextEditingController _noteCtrl =
      TextEditingController(text: widget.existing?.note ?? '');
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _noteCtrl.dispose();
    for (final r in _rows) {
      r.qtyCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _addPrestation() async {
    final active = ref.read(activePrestationsProvider).value ?? const [];
    final inUseIds = _rows.map((r) => r.prestationId).toSet();
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
      builder: (sheetCtx) => _PrestationPickerSheet(
        candidates: candidates,
        catsById: cats,
        speciesById: speciesById,
      ),
    );
    if (picked == null) return;
    final cat = picked.categoryId == null ? null : cats[picked.categoryId];
    final spec = cat == null ? null : speciesById[cat.speciesId];
    setState(() {
      _rows.add(_Row(
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

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_date == null) {
      showFToast(context: context, title: Text(l.manualEntryDateRequired));
      return;
    }
    setState(() => _saving = true);
    final manual = ref.read(manualHistoryRepositoryProvider);
    final clients = ref.read(clientRepositoryProvider);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final date = _date!;

    // Re-snapshot from current active list at save time. If a prestation no
    // longer exists in active (deleted/archived), preserve the row's existing
    // snapshot fields.
    final active = ref.read(activePrestationsProvider).value ?? const [];
    final activeById = {for (final p in active) p.id: p};
    final cats = ref.read(allCategoriesByIdProvider).value ??
        const <int, AnimalCategory>{};
    final speciesList = ref.read(activeSpeciesProvider).value ?? const [];
    final speciesById = {for (final s in speciesList) s.id: s};

    final prestations = <TourStopPrestation>[];
    for (final r in _rows) {
      if (!r.checked) continue;
      if (r.qty <= 0) continue;
      final p = activeById[r.prestationId];
      if (p != null) {
        final cat = p.categoryId == null ? null : cats[p.categoryId];
        final spec = cat == null ? null : speciesById[cat.speciesId];
        prestations.add(TourStopPrestation(
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
        prestations.add(TourStopPrestation(
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

    if (_isEdit) {
      await manual.update(
        widget.existing!.id,
        date: date,
        prestations: prestations,
        note: note,
      );
      await clients.recomputeClientFromHistory(widget.clientId);
    } else {
      await manual.insert(
        clientId: widget.clientId,
        date: date,
        prestations: prestations,
        note: note,
      );
      await clients.applyManualEntryToClient(
        widget.clientId,
        date: date,
        prestations: prestations,
      );
    }

    _invalidateProviders();
    if (!mounted) return;
    showFToast(context: context, title: Text(l.manualEntrySaved));
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        body: Text(l.manualEntryDeleteConfirm),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(l.manualEntryDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    final manual = ref.read(manualHistoryRepositoryProvider);
    final clients = ref.read(clientRepositoryProvider);
    await manual.delete(widget.existing!.id);
    await clients.recomputeClientFromHistory(widget.clientId);

    _invalidateProviders();
    if (!mounted) return;
    showFToast(context: context, title: Text(l.manualEntryDeleted));
    Navigator.of(context).pop();
  }

  void _invalidateProviders() {
    ref.invalidate(historyForClientProvider(widget.clientId));
    ref.invalidate(clientsAsyncProvider);
    ref.invalidate(clientNotesMapProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final dateLabel = _date == null
        ? l.manualEntryDatePlaceholder
        : DateFormat('dd/MM/yyyy').format(_date!);

    return ColoredBox(
      color: theme.colors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit
                  ? l.manualEntrySheetTitleEdit
                  : l.manualEntrySheetTitleCreate,
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            FTile(
              prefix: const Icon(FIcons.calendar),
              title: Text(l.manualEntryDateLabel),
              subtitle: Text(dateLabel),
              onPress: _saving ? null : _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var ri = 0; ri < _rows.length; ri++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PrestationRowEditor(
                  row: _rows[ri],
                  onCheckedChanged: (v) =>
                      setState(() => _rows[ri].checked = v),
                  onQtyChanged: (q) => setState(() => _rows[ri].qty = q),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: _saving ? null : _addPrestation,
                child: Text(l.tourCompletionAddOffPlan),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FTextField(
              control: FTextFieldControl.managed(controller: _noteCtrl),
              label: Text(l.manualEntryNoteLabel),
              maxLines: 3,
              enabled: !_saving,
            ),
            const SizedBox(height: AppSpacing.md),
            FButton(
              onPress: _saving ? null : _save,
              child: Text(l.manualEntrySave),
            ),
            if (_isEdit) ...[
              const SizedBox(height: AppSpacing.sm),
              FButton(
                variant: FButtonVariant.destructive,
                onPress: _saving ? null : _delete,
                child: Text(l.manualEntryDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row {
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

  _Row({
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
  final _Row row;
  final ValueChanged<bool> onCheckedChanged;
  final ValueChanged<int> onQtyChanged;

  const _PrestationRowEditor({
    required this.row,
    required this.onCheckedChanged,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final subtitleParts = <String>[];
    if (row.categoryNameSnapshot != null) {
      subtitleParts.add(
        '${row.speciesNameSnapshot ?? '?'}/${row.categoryNameSnapshot}',
      );
    }

    return Container(
      padding: AppSizes.listTilePadding,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCheckedChanged(!row.checked),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: row.checked ? theme.colors.primary : null,
                border: row.checked
                    ? null
                    : Border.all(color: theme.colors.border, width: 2),
              ),
              child: row.checked
                  ? Icon(
                      FIcons.check,
                      color: theme.colors.primaryForeground,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.nameSnapshot,
                  style: theme.typography.md.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      subtitleParts.join(' · '),
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '×',
            style: theme.typography.lg.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 72,
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

class _PrestationPickerSheet extends StatelessWidget {
  final List<Prestation> candidates;
  final Map<int, AnimalCategory> catsById;
  final Map<int, Species> speciesById;

  const _PrestationPickerSheet({
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
