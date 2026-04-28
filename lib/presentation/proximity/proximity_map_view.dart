// lib/presentation/proximity/proximity_map_view.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../state/proximity_controller.dart';

class ProximityMapView extends ConsumerWidget {
  final int pivotId;
  const ProximityMapView({super.key, required this.pivotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final pivot = ref.watch(pivotClientProvider(pivotId)).value;
    final results = ref.watch(proximityResultsProvider).value ?? const [];
    if (pivot == null) {
      return const Center(child: FCircularProgress());
    }
    final pivotLatLng = LatLng(pivot.coordinates.lat, pivot.coordinates.lon);
    final selection = ref.watch(tourSelectionProvider);

    return FlutterMap(
      options: MapOptions(
        initialCenter: pivotLatLng,
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'fr.coupelaine',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: pivotLatLng,
              width: 40,
              height: 40,
              child: Icon(
                FIcons.star,
                color: theme.colors.primary,
                size: 40,
              ),
            ),
            for (final r in results)
              Marker(
                point: LatLng(
                    r.client.coordinates.lat, r.client.coordinates.lon),
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => ref
                      .read(tourSelectionProvider.notifier)
                      .toggle(r.client.id),
                  child: Icon(
                    FIcons.mapPin,
                    color: selection.contains(r.client.id)
                        ? theme.colors.primary
                        : theme.colors.mutedForeground,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
