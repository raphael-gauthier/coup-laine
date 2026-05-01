// lib/presentation/tours/tour_draft_screen.dart
import 'package:flutter/material.dart' show Material, MaterialType, ReorderableListView, TimeOfDay, showDatePicker, showTimePicker;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../../state/proximity_controller.dart';
import '../../state/providers.dart';
import '../../state/tour_draft_controller.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_stepper.dart';
import '../widgets/mini_map.dart';
import '../widgets/waiting_clients_multi_picker.dart';
import 'prestation_picker_sheet.dart';
import 'tours_list_screen.dart' show toursAsyncProvider;

class TourDraftScreen extends ConsumerStatefulWidget {
  final int? pivotId;
  final int? editingTourId;
  const TourDraftScreen({super.key, this.pivotId, this.editingTourId});

  @override
  ConsumerState<TourDraftScreen> createState() => _TourDraftScreenState();
}

/// One-shot loader for the tour being edited. Local to this screen — no
/// other consumer needs it.
final _editingTourLoaderProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});

class _TourDraftScreenState extends ConsumerState<TourDraftScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _startMinutes = 8 * 60;
  List<int>? _manualOrder;
  bool _prefilled = false;

  int _step = 0;

  bool get _isEditing => widget.editingTourId != null;

  // Step 0 is always ready (date has a default value)
  bool get _step0Ready => true;

  bool _step1Ready(TourDraftBundle? bundle) =>
      bundle != null && bundle.orderedClients.isNotEmpty;

  bool _canGoNext(TourDraftBundle? bundle) {
    if (_step == 0) return _step0Ready;
    if (_step == 1) return _step1Ready(bundle);
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Fresh draft: start with no picker selections.
        ref.read(tourDraftPrestationsProvider.notifier).clear();
        _refresh();
      });
    }
  }

  Future<void> _loadForEdit() async {
    final tour = await ref.read(_editingTourLoaderProvider(widget.editingTourId!).future);
    if (!mounted) return;
    if (tour == null) {
      // Tour vanished (deleted concurrently). Pop back.
      if (context.canPop()) context.pop();
      return;
    }
    final orderedIds = [
      for (final s in tour.stops)
        if (s.clientId != null) s.clientId!,
    ];
    setState(() {
      _date = tour.tour.plannedDate;
      _startMinutes = tour.tour.startTimeMinutes;
      _manualOrder = orderedIds;
      _prefilled = true;
    });
    final notifier = ref.read(tourSelectionProvider.notifier);
    notifier.clear();
    for (final id in orderedIds) {
      notifier.toggle(id);
    }
    // Seed picker selections from the existing tour stops so the user sees
    // their previous choices when re-opening the draft.
    final pres = ref.read(tourDraftPrestationsProvider.notifier);
    pres.clear();
    for (final s in tour.stops) {
      if (s.clientId != null && s.plannedPrestations.isNotEmpty) {
        pres.setForClient(s.clientId!, s.plannedPrestations);
      }
    }
    _refresh();
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

  Future<void> _openPicker(
    BuildContext context,
    Client client,
    List<TourStopPrestation> current,
  ) async {
    final result = await showPrestationPickerSheet(
      context,
      clientName: client.name,
      clientAnimals: client.animals,
      initialSelection: current,
    );
    if (result != null) {
      ref
          .read(tourDraftPrestationsProvider.notifier)
          .setForClient(client.id, result);
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
        plannedPrestations: bundle.result.plannedPrestationsPerStop[i],
        feeShareCents: bundle.result.feeShareCents[i],
      ));
    }

    // Reuse the route geometry already fetched (and cached) by the live
    // provider feeding the MiniMap on step 3 — avoids a redundant ORS call.
    // Returns null silently on offline / quota / error, in which case the
    // tour is persisted without geometry and the map falls back to straight
    // lines.
    List<Coordinates>? routeGeometry;
    try {
      routeGeometry = await ref.read(tourDraftRouteGeometryProvider.future);
    } catch (_) {
      routeGeometry = null;
    }

    final draft = TourDraft(
      plannedDate: _date,
      startTimeMinutes: _startMinutes,
      totalDistanceMeters: bundle.result.totalDistanceMeters,
      totalDriveSeconds: bundle.result.totalDriveSeconds,
      totalTravelFeeCents: bundle.result.totalFeeCents,
      stops: stops,
      routeGeometry: routeGeometry,
    );

    final repo = ref.read(tourRepositoryProvider);
    final int destinationId;
    if (_isEditing) {
      await repo.update(widget.editingTourId!, draft);
      destinationId = widget.editingTourId!;
    } else {
      destinationId = await repo.plan(draft);
    }
    if (!mounted) return;
    ref.read(tourSelectionProvider.notifier).clear();
    ref.invalidate(toursAsyncProvider);
    if (_isEditing) {
      ref.invalidate(_editingTourLoaderProvider(widget.editingTourId!));
      ref.invalidate(tourByIdProvider(widget.editingTourId!));
    }
    context.go('/tours/$destinationId');
  }

  Future<void> _openEditSelection(
      BuildContext context, TourDraftBundle bundle) async {
    final l = AppLocalizations.of(context)!;
    final initial = bundle.orderedClients.map((c) => c.id).toSet();
    var working = {...initial};
    final anchorKey = (initial.toList()..sort()).join(',');
    await showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (innerCtx, setSheetState) {
            return ColoredBox(
              color: innerCtx.theme.colors.background,
              child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: MediaQuery.of(innerCtx).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        l.tourDraftEditSelectionSheetTitle,
                        style: innerCtx.theme.typography.lg.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Consumer(builder: (ctx, ref, _) {
                        final nearbyAsync =
                            ref.watch(nearbyToAnchorsProvider(anchorKey));
                        final nearbyIds =
                            nearbyAsync.maybeWhen(data: (v) => v, orElse: () => const <int>{});
                        return WaitingClientsMultiPicker(
                          initialSelection: working,
                          alwaysIncludeIds: initial,
                          nearbyIds: nearbyIds,
                          onSelectionChanged: (s) =>
                              setSheetState(() => working = s),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: l.tourDraftEditSelectionValidate,
                      onPress: working.isEmpty
                          ? null
                          : () {
                              Navigator.of(innerCtx).pop();
                              setState(() => _manualOrder = null);
                              final notifier =
                                  ref.read(tourSelectionProvider.notifier);
                              notifier.clear();
                              for (final id in working) {
                                notifier.toggle(id);
                              }
                              ref.read(tourDraftInputProvider.notifier).state =
                                  TourDraftInput(
                                pivotId: widget.pivotId,
                                selectedIds: working.toList(),
                                plannedDate: _date,
                                startTimeMinutes: _startMinutes,
                                overrideOrder: null,
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Step builders
  // ---------------------------------------------------------------------------

  Widget _buildStepWhen(BuildContext context, AppLocalizations l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: AppSectionCard(
        icon: FIcons.calendarClock,
        title: l.tourDraftWhenTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppListTile(
              variant: AppListTileVariant.standard,
              prefix: const Icon(FIcons.calendar),
              title: l.tourDraftDate,
              subtitle: DateFormat('d MMM yyyy', 'fr').format(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppListTile(
              variant: AppListTileVariant.standard,
              prefix: const Icon(FIcons.clock),
              title: l.tourDraftStart,
              subtitle: formatHm(_startMinutes),
              onTap: _pickTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWho(BuildContext context, AppLocalizations l) {
    return WaitingClientsMultiPicker(
      initialSelection: ref.read(tourSelectionProvider),
      onSelectionChanged: (selection) {
        setState(() => _manualOrder = null);
        final notifier = ref.read(tourSelectionProvider.notifier);
        notifier.clear();
        for (final id in selection) {
          notifier.toggle(id);
        }
        ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
          pivotId: widget.pivotId,
          selectedIds: selection.toList(),
          plannedDate: _date,
          startTimeMinutes: _startMinutes,
          overrideOrder: null,
        );
      },
    );
  }

  Widget _buildStepWhat(BuildContext context, AppLocalizations l, TourDraftBundle bundle) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Étapes" heading
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.tourDraftStepsTitle,
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      prefix: const Icon(FIcons.zap, size: 16),
                      onPress: () {
                        setState(() => _manualOrder = null);
                        _refresh();
                      },
                      child: Text(l.tourDraftOptimizeOrder),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      prefix: const Icon(FIcons.pencil, size: 16),
                      onPress: () => _openEditSelection(context, bundle),
                      child: Text(l.tourDraftEditSelection),
                    ),
                  ),
                ],
              ),
            ],
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
                final stopPres =
                    bundle.result.plannedPrestationsPerStop[i];
                final stopMinutes = stopPres.fold<int>(
                    0, (sum, p) => sum + p.qty * p.minutesSnapshot);
                final stopRevenue =
                    bundle.result.revenueCentsPerStop[i];
                return Padding(
                  key: ValueKey(c.id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: FTile(
                    onPress: () => _openPicker(context, c, stopPres),
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
                    title: Text(c.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.tourDraftStopArrivalFmt(
                              formatHm(arr), formatHm(dep)),
                        ),
                        if (stopPres.isEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FIcons.triangleAlert,
                                size: 14,
                                color: theme.colors.destructive,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                l.tourDraftStopNoPrestation,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.destructive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            l.tourDraftStopNPrestationsFmt(
                              stopPres.length,
                              formatDuration(stopMinutes),
                              formatEuros(stopRevenue),
                            ),
                          ),
                      ],
                    ),
                    details: Text(fee),
                    suffix: const Icon(FIcons.gripVertical),
                  ),
                );
              },
            ),
          ),
        ),
        // MiniMap preview (shown when base is available and ≥1 stop)
        Builder(builder: (context) {
          final settingsAsync = ref.watch(settingsRepositoryFutureProvider);
          final base = settingsAsync.value?.baseCoordinates;
          if (base == null || bundle.orderedClients.isEmpty) {
            return const SizedBox.shrink();
          }
          // Live ORS geometry for the current ordered draft (refetched on
          // each reorder / picker change). Falls back to straight lines if
          // not yet loaded or on error.
          final geomAsync = ref.watch(tourDraftRouteGeometryProvider);
          final geom = geomAsync.value;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
            ),
            child: MiniMap(
              base: LatLng(base.lat, base.lon),
              waypoints: [
                for (final c in bundle.orderedClients)
                  LatLng(c.coordinates.lat, c.coordinates.lon),
              ],
              routeGeometry: geom == null
                  ? null
                  : [
                      for (final c in geom) LatLng(c.lat, c.lon),
                    ],
              height: 140,
            ),
          );
        }),
        // Summary footer (KpiRow)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: AppKpiRow(
            cells: [
              AppKpiCell(
                value: (bundle.result.totalDistanceMeters / 1000)
                    .toStringAsFixed(0),
                label: 'km',
              ),
              AppKpiCell(
                value: formatDuration(
                    bundle.result.totalDriveSeconds ~/ 60),
                label: 'durée',
              ),
              if (bundle.result.totalRevenueCents > 0)
                AppKpiCell(
                  value: formatEuros(bundle.result.totalRevenueCents),
                  label: 'revenu',
                  valueColor: theme.colors.secondary,
                ),
              AppKpiCell(
                value: formatHm(bundle.result.endTimeMinutes),
                label: 'fin',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(tourDraftProvider);
    final title = _isEditing ? l.tourEditTitle : l.tourDraftTitle;
    final isLoadingPrefill = _isEditing && !_prefilled;

    return SafeArea(
      bottom: false,
      child: FScaffold(
        resizeToAvoidBottomInset: true,
        child: isLoadingPrefill
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(title: title),
                  const Expanded(child: Center(child: FCircularProgress())),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(title: title),
                  AppStepper(
                    currentIndex: _step,
                    labels: [
                      l.tourDraftStepDate,
                      l.tourDraftStepClients,
                      l.tourDraftStepPrestations,
                    ],
                  ),
                  Expanded(
                    child: async.when(
                      loading: () => const Center(child: FCircularProgress()),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (bundle) {
                        if (bundle == null) {
                          return const Center(child: FCircularProgress());
                        }
                        return IndexedStack(
                          index: _step,
                          children: [
                            _buildStepWhen(context, l),
                            _buildStepWho(context, l),
                            _buildStepWhat(context, l, bundle),
                          ],
                        );
                      },
                    ),
                  ),
                  async.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (bundle) {
                      final canNext = _canGoNext(bundle);
                      if (_step < 2) {
                        return AppActionBar(
                          secondary: _step > 0
                              ? AppPrimaryButton(
                                  label: l.onboardingPrevious,
                                  variant: FButtonVariant.outline,
                                  onPress: () =>
                                      setState(() => _step -= 1),
                                )
                              : AppPrimaryButton(
                                  label: l.onboardingPrevious,
                                  variant: FButtonVariant.outline,
                                  onPress: null,
                                ),
                          primary: AppPrimaryButton(
                            label: l.onboardingStep1Cta,
                            onPress: canNext
                                ? () => setState(() => _step += 1)
                                : null,
                          ),
                        );
                      }
                      // Step 2
                      return AppActionBar(
                        secondary: AppPrimaryButton(
                          label: l.onboardingPrevious,
                          variant: FButtonVariant.outline,
                          onPress: () => setState(() => _step -= 1),
                        ),
                        primary: AppPrimaryButton(
                          label: l.tourDraftConfirm,
                          onPress: bundle != null
                              ? () => _save(bundle)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
