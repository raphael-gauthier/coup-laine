import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../data/repositories/tour_repository.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart'
    show clientsAsyncProvider, clientNotesMapProvider;
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
      d.smallCtrl.dispose();
      d.largeCtrl.dispose();
      d.noteCtrl.dispose();
    }
    super.dispose();
  }

  void _ensureDrafts(TourWithStops bundle) {
    if (_initialised) return;
    for (final s in bundle.stops) {
      if (s.clientId == null) continue;
      _drafts[s.id] = _StopDraft(
        smallCtrl: TextEditingController(text: s.plannedSmall.toString()),
        largeCtrl: TextEditingController(text: s.plannedLarge.toString()),
        noteCtrl: TextEditingController(),
      );
    }
    _initialised = true;
  }

  Future<void> _confirm(TourWithStops bundle) async {
    final l = AppLocalizations.of(context)!;
    final actuals =
        <int, ({int actualSmall, int actualLarge, String? note})>{};
    for (final entry in _drafts.entries) {
      final small = int.tryParse(entry.value.smallCtrl.text) ?? 0;
      final large = int.tryParse(entry.value.largeCtrl.text) ?? 0;
      final note = entry.value.noteCtrl.text.trim();
      actuals[entry.key] = (
        actualSmall: small,
        actualLarge: large,
        note: note.isEmpty ? null : note,
      );
    }
    setState(() => _saving = true);
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
    final async = ref.watch(_tourForCompletionProvider(widget.tourId));

    return SafeArea(
      child: FScaffold(
        resizeToAvoidBottomInset: true,
        header: FHeader.nested(title: Text(l.tourCompletionTitle)),
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            _ensureDrafts(bundle);
            final visibleStops =
                bundle.stops.where((s) => s.clientId != null).toList();
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: AppSizes.screenPadding,
                    itemCount: visibleStops.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final s = visibleStops[i];
                      final draft = _drafts[s.id]!;
                      return AppSectionCard(
                        icon: FIcons.user,
                        title: s.clientNameSnapshot,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: draft.smallCtrl,
                              ),
                              label: Text(l.clientFormSheepCountSmall),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: draft.largeCtrl,
                              ),
                              label: Text(l.clientFormSheepCountLarge),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: AppPrimaryButton(
                    label: l.tourCompletionConfirm,
                    prefixIcon: FIcons.check,
                    loading: _saving,
                    onPress: _saving ? null : () => _confirm(bundle),
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
  final TextEditingController smallCtrl;
  final TextEditingController largeCtrl;
  final TextEditingController noteCtrl;
  _StopDraft({
    required this.smallCtrl,
    required this.largeCtrl,
    required this.noteCtrl,
  });
}
