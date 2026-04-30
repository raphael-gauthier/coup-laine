import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../state/proximity_controller.dart';
import '../../state/tour_draft_controller.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/waiting_clients_multi_picker.dart';

class TourManualPickerScreen extends ConsumerStatefulWidget {
  const TourManualPickerScreen({super.key});

  @override
  ConsumerState<TourManualPickerScreen> createState() =>
      _TourManualPickerScreenState();
}

class _TourManualPickerScreenState
    extends ConsumerState<TourManualPickerScreen> {
  Set<int> _selection = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  void _continue() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
      pivotId: null,
      selectedIds: _selection.toList(),
      plannedDate: tomorrow,
      startTimeMinutes: 8 * 60,
    );
    // Mirror selection so the legacy provider stays consistent if any UI
    // observes it.
    final notifier = ref.read(tourSelectionProvider.notifier);
    notifier.clear();
    for (final id in _selection) {
      notifier.toggle(id);
    }
    context.push('/tours/draft');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final footer = _selection.isEmpty
        ? null
        : Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colors.border)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text(l.manualPickerSelectedFmt(_selection.length)),
                const Spacer(),
                AppPrimaryButton(
                  label: l.manualPickerContinue,
                  prefixIcon: FIcons.arrowRight,
                  onPress: _continue,
                ),
              ],
            ),
          );
    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.manualPickerTitle)),
        footer: footer,
        child: WaitingClientsMultiPicker(
          initialSelection: _selection,
          onSelectionChanged: (s) => setState(() => _selection = s),
        ),
      ),
    );
  }
}
