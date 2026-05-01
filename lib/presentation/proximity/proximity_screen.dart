// lib/presentation/proximity/proximity_screen.dart
import 'package:flutter/material.dart' show Material, MaterialType, Slider;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../state/proximity_controller.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
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
    final selection = ref.watch(tourSelectionProvider);
    final pivotAsync = ref.watch(pivotClientProvider(widget.pivotId));
    final pivot = pivotAsync.value;
    final nearbyResults = ref.watch(proximityResultsProvider).value;

    // --- NICE: KPI row (no new providers, data already watched) ---
    Widget? kpiRow;
    if (nearbyResults != null && nearbyResults.isNotEmpty) {
      final found = nearbyResults.length;
      final avgKm = (nearbyResults.map((e) => e.distanceMeters).reduce((a, b) => a + b) /
              found /
              1000)
          .toStringAsFixed(1);
      kpiRow = Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
        child: AppKpiRow(cells: [
          AppKpiCell(value: '$found', label: 'trouvés'),
          AppKpiCell(value: '${selection.length}', label: 'sélectionnés'),
          AppKpiCell(value: '$avgKm km', label: 'distance moy.'),
        ]),
      );
    }

    // --- SHOULD: bottom CTA via AppActionBar ---
    Widget? footer;
    if (selection.isNotEmpty) {
      footer = AppActionBar(
        primary: AppPrimaryButton(
          label: '${l.proximityPlanTour} (${selection.length})',
          prefixIcon: FIcons.route,
          onPress: () => context.push('/tours/draft?pivot=${widget.pivotId}'),
        ),
      );
    }

    return SafeArea(
      child: FScaffold(
        // --- MUST: AppHeader replaces FHeader.nested ---
        header: AppHeader(
          title: pivot != null
              ? 'À proximité de ${pivot.name}'
              : l.proximityTitle,
          subtitle: pivot?.city,
        ),
        footer: footer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kpiRow != null) kpiRow,
            // Radius card
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
              child: AppSectionCard(
                icon: FIcons.compass,
                title: l.proximityRadiusTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_radiusKm km',
                      style: context.theme.typography.xl2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Material(
                      type: MaterialType.transparency,
                      child: Slider(
                        min: 5,
                        max: 30,
                        divisions: 5,
                        value: _radiusKm.toDouble(),
                        label: '$_radiusKm km',
                        onChanged: (v) => _setRadius(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tabs (list / map) — FTabs with expands:true fills remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
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
      ),
    );
  }
}
