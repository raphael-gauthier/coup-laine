import 'package:flutter/material.dart' show Locale, showDatePicker;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/manual_history_entry.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;

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
  late final TextEditingController _smallCtrl =
      TextEditingController(text: '${widget.existing?.small ?? 0}');
  late final TextEditingController _largeCtrl =
      TextEditingController(text: '${widget.existing?.large ?? 0}');
  late final TextEditingController _noteCtrl =
      TextEditingController(text: widget.existing?.note ?? '');
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _smallCtrl.dispose();
    _largeCtrl.dispose();
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
    final small = int.tryParse(_smallCtrl.text.trim()) ?? 0;
    final large = int.tryParse(_largeCtrl.text.trim()) ?? 0;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final date = _date!;

    if (_isEdit) {
      await manual.update(
        widget.existing!.id,
        date: date,
        small: small,
        large: large,
        note: note,
      );
      await clients.recomputeClientFromHistory(widget.clientId);
    } else {
      await manual.insert(
        clientId: widget.clientId,
        date: date,
        small: small,
        large: large,
        note: note,
      );
      await clients.applyManualEntryToClient(
        widget.clientId,
        date: date,
        small: small,
        large: large,
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
      child: Padding(
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
          FTextField(
            control: FTextFieldControl.managed(controller: _smallCtrl),
            label: Text(l.manualEntrySmallLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            enabled: !_saving,
          ),
          const SizedBox(height: AppSpacing.sm),
          FTextField(
            control: FTextFieldControl.managed(controller: _largeCtrl),
            label: Text(l.manualEntryLargeLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            enabled: !_saving,
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
