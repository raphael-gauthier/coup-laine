// lib/presentation/tours/tour_draft_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../state/proximity_controller.dart';
import '../../state/providers.dart';
import '../../state/tour_draft_controller.dart';
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
    final async = ref.watch(tourDraftProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.tourDraftTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bundle) {
          if (bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l.tourDraftDate),
                subtitle: Text(DateFormat('EEE dd/MM/yyyy', 'fr').format(_date)),
                onTap: _pickDate,
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l.tourDraftStart),
                subtitle: Text(formatHm(_startMinutes)),
                onTap: _pickTime,
              ),
              const Divider(),
              Expanded(
                child: ReorderableListView.builder(
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
                    return ListTile(
                      key: ValueKey(c.id),
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(c.name),
                      subtitle: Text(l.tourDraftStopArrivalFmt(
                        formatHm(arr),
                        formatHm(dep),
                      )),
                      trailing: Text(formatEuros(bundle.result.feeShareCents[i])),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(l.tourDraftSummaryTotal(
                  (bundle.result.totalDistanceMeters / 1000).toStringAsFixed(1),
                  formatDuration(bundle.result.totalDriveSeconds ~/ 60),
                  formatDuration(bundle.result.totalShearingMinutes),
                  formatHm(bundle.result.endTimeMinutes),
                )),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _manualOrder = null);
                          _refresh();
                        },
                        child: Text(l.tourDraftOptimise),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _save(bundle),
                        child: Text(l.tourDraftConfirm),
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
