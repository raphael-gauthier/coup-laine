// lib/presentation/tours/tour_draft_screen.dart
import 'package:flutter/material.dart' show Material, MaterialType, ReorderableListView, TimeOfDay, showDatePicker, showTimePicker;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../state/proximity_controller.dart';
import '../../state/providers.dart';
import '../../state/tour_draft_controller.dart';
import '../widgets/app_hero_card.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import 'tours_list_screen.dart' show toursAsyncProvider;

class TourDraftScreen extends ConsumerStatefulWidget {
  final int pivotId;
  const TourDraftScreen({super.key, required this.pivotId});

  @override
  ConsumerState<TourDraftScreen> createState() => _TourDraftScreenState();
}

class _TourDraftScreenState extends ConsumerState<TourDraftScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _startMinutes = 8 * 60;
  List<int>? _manualOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    final selection = ref.read(tourSelectionProvider);
    ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
      pivotId: widget.pivotId,
      selectedIds: selection.toList(),
      plannedDate: _date,
      startTimeMinutes: _startMinutes,
      overrideOrder: _manualOrder,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _refresh();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _startMinutes ~/ 60, minute: _startMinutes % 60),
    );
    if (picked != null) {
      setState(() => _startMinutes = picked.hour * 60 + picked.minute);
      _refresh();
    }
  }

  Future<void> _save(TourDraftBundle bundle) async {
    final stops = <TourStopDraft>[];
    for (var i = 0; i < bundle.orderedClients.length; i++) {
      final c = bundle.orderedClients[i];
      stops.add(TourStopDraft(
        clientId: c.id,
        clientNameSnapshot: c.name,
        orderIndex: i,
        estimatedArrivalMinutes: bundle.result.arrivalMinutes[i],
        estimatedDepartureMinutes: bundle.result.departureMinutes[i],
        sheepCountSnapshot: c.sheepCount,
        minutesPerSheepSnapshot: bundle.result.minutesPerSheepPerStop[i],
        feeShareCents: bundle.result.feeShareCents[i],
      ));
    }
    final tourId = await ref.read(tourRepositoryProvider).plan(
          TourDraft(
            plannedDate: _date,
            startTimeMinutes: _startMinutes,
            totalDistanceMeters: bundle.result.totalDistanceMeters,
            totalDriveSeconds: bundle.result.totalDriveSeconds,
            totalTravelFeeCents: bundle.result.totalFeeCents,
            stops: stops,
          ),
        );
    if (!mounted) return;
    ref.read(tourSelectionProvider.notifier).clear();
    ref.invalidate(toursAsyncProvider);
    context.go('/tours/$tourId');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(tourDraftProvider);

    return FScaffold(
      resizeToAvoidBottomInset: true,
      header: FHeader.nested(title: Text(l.tourDraftTitle)),
      child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bundle) {
          if (bundle == null) {
            return const Center(child: FCircularProgress());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date/time card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: AppSectionCard(
                  icon: FIcons.calendarClock,
                  title: l.tourDraftWhenTitle,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppListTile(
                          prefix: const Icon(FIcons.calendar),
                          title: l.tourDraftDate,
                          subtitle: DateFormat('d MMM yyyy', 'fr').format(_date),
                          onPress: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppListTile(
                          prefix: const Icon(FIcons.clock),
                          title: l.tourDraftStart,
                          subtitle: formatHm(_startMinutes),
                          onPress: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "Étapes" heading
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 4),
                child: Text(
                  l.tourDraftStepsTitle,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              // Reorderable list
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: bundle.orderedClients.length,
                    onReorder: (oldIndex, newIndex) {
                      final order =
                          bundle.orderedClients.map((c) => c.id).toList();
                      if (newIndex > oldIndex) newIndex -= 1;
                      final id = order.removeAt(oldIndex);
                      order.insert(newIndex, id);
                      setState(() => _manualOrder = order);
                      _refresh();
                    },
                    itemBuilder: (_, i) {
                      final c = bundle.orderedClients[i];
                      final arr = bundle.result.arrivalMinutes[i];
                      final dep = bundle.result.departureMinutes[i];
                      final fee = formatEuros(bundle.result.feeShareCents[i]);
                      return Padding(
                        key: ValueKey(c.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppListTile(
                          prefix: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.primaryForeground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: c.name,
                          subtitle:
                              '${l.tourDraftStopArrivalFmt(formatHm(arr), formatHm(dep))} · $fee',
                          suffix: const Icon(FIcons.gripVertical),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Summary footer
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: AppHeroCard(
                  bigNumber:
                      (bundle.result.totalDistanceMeters / 1000).toStringAsFixed(0),
                  label: 'km au total',
                  subtitle:
                      '${formatDuration(bundle.result.totalDriveSeconds ~/ 60)} de trajet · Fin ${formatHm(bundle.result.endTimeMinutes)}',
                ),
              ),
              // Action row
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: () {
                          setState(() => _manualOrder = null);
                          _refresh();
                        },
                        child: Text(l.tourDraftOptimise),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppPrimaryButton(
                          label: l.tourDraftConfirm,
                          onPress: () => _save(bundle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
