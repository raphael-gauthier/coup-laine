import 'package:flutter/material.dart' show Locale, showDatePicker;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/manual_history_entry.dart';
import '../../domain/models/tour_stop_animal.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart'
    show clientsAsyncProvider, clientNotesMapProvider;
import '../widgets/animal_counts_editor.dart';

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
  late List<AnimalCount> _animals = widget.existing?.animals
          .map((a) => AnimalCount(categoryId: a.categoryId, count: a.count))
          .toList() ??
      const <AnimalCount>[];
  late final TextEditingController _noteCtrl =
      TextEditingController(text: widget.existing?.note ?? '');
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _noteCtrl.dispose();
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

    final lookup = await ref.read(categoryLookupProvider.future);
    final tourStopAnimals = <TourStopAnimal>[
      for (final ac in _animals)
        if (lookup[ac.categoryId] != null)
          TourStopAnimal(
            categoryId: ac.categoryId,
            count: ac.count,
            categoryNameSnapshot: lookup[ac.categoryId]!.categoryName,
            speciesNameSnapshot: lookup[ac.categoryId]!.speciesName,
            minutesSnapshot: lookup[ac.categoryId]!.minutes,
          ),
    ];

    if (_isEdit) {
      await manual.update(
        widget.existing!.id,
        date: date,
        animals: tourStopAnimals,
        note: note,
      );
      await clients.recomputeClientFromHistory(widget.clientId);
    } else {
      await manual.insert(
        clientId: widget.clientId,
        date: date,
        animals: tourStopAnimals,
        note: note,
      );
      await clients.applyManualEntryToClient(
        widget.clientId,
        date: date,
        animals: tourStopAnimals,
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
          AnimalCountsEditor(
            value: _animals,
            onChanged: (next) => setState(() => _animals = next),
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
