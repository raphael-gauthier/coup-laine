// lib/presentation/proximity/proximity_screen.dart
import 'package:flutter/material.dart' show Slider;
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../state/proximity_controller.dart';
import 'proximity_list_view.dart';
import 'proximity_map_view.dart';

class ProximityScreen extends ConsumerStatefulWidget {
  final int pivotId;
  const ProximityScreen({super.key, required this.pivotId});

  @override
  ConsumerState<ProximityScreen> createState() => _ProximityScreenState();
}

class _ProximityScreenState extends ConsumerState<ProximityScreen> {
  int _radiusKm = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proximityRequestProvider.notifier).state = ProximityRequest(
        pivotId: widget.pivotId,
        radiusKm: _radiusKm,
      );
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  void _setRadius(int km) {
    setState(() => _radiusKm = km);
    ref.read(proximityRequestProvider.notifier).state = ProximityRequest(
      pivotId: widget.pivotId,
      radiusKm: km,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final selection = ref.watch(tourSelectionProvider);
    final pivotAsync = ref.watch(pivotClientProvider(widget.pivotId));
    final pivot = pivotAsync.value;

    final footer = selection.isEmpty
        ? null
        : Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colors.border),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(l.proximitySelectedCount(selection.length)),
                const Spacer(),
                FButton(
                  onPress: () =>
                      context.push('/tours/draft?pivot=${widget.pivotId}'),
                  child: Text(l.proximityPlanTour),
                ),
              ],
            ),
          );

    return FScaffold(
      header: FHeader.nested(
        title: Text(pivot?.name ?? l.proximityTitle),
      ),
      footer: footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pivot info row
          if (pivot != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                pivot.city,
                style: theme.typography.sm
                    .copyWith(color: theme.colors.mutedForeground),
              ),
            ),
          // Radius card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FCard(
              title: Text(l.proximityRadiusTitle),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_radiusKm km',
                    style: theme.typography.xl2
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    min: 5,
                    max: 30,
                    divisions: 5,
                    value: _radiusKm.toDouble(),
                    label: '$_radiusKm km',
                    onChanged: (v) => _setRadius(v.round()),
                  ),
                ],
              ),
            ),
          ),
          // Tabs (list / map) — FTabs with expands:true fills remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FTabs(
                expands: true,
                children: [
                  FTabEntry(
                    label: Text(l.proximityTabList),
                    child: const ProximityListView(),
                  ),
                  FTabEntry(
                    label: Text(l.proximityTabMap),
                    child: ProximityMapView(pivotId: widget.pivotId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
