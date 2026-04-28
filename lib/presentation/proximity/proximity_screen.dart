// lib/presentation/proximity/proximity_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _ProximityScreenState extends ConsumerState<ProximityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _radiusKm = 15;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proximityRequestProvider.notifier).state = ProximityRequest(
        pivotId: widget.pivotId,
        radiusKm: _radiusKm,
      );
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(pivotAsync.value?.name ?? l.proximityTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.proximityTabList),
            Tab(text: l.proximityTabMap),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(l.proximityRadiusLabel(_radiusKm)),
                Expanded(
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
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const ProximityListView(),
                ProximityMapView(pivotId: widget.pivotId),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: selection.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(l.proximitySelectedCount(selection.length)),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => context
                          .push('/tours/draft?pivot=${widget.pivotId}'),
                      child: Text(l.proximityPlanTour),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
