// lib/presentation/proximity/proximity_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../state/proximity_controller.dart';

class ProximityMapView extends ConsumerWidget {
  final int pivotId;
  const ProximityMapView({super.key, required this.pivotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pivot = ref.watch(pivotClientProvider(pivotId)).value;
    final results = ref.watch(proximityResultsProvider).value ?? const [];
    if (pivot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final pivotLatLng =
        LatLng(pivot.coordinates.lat, pivot.coordinates.lon);
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
              width: 36,
              height: 36,
              child: const Icon(Icons.star, color: Colors.deepOrange, size: 36),
            ),
            for (final r in results)
              Marker(
                point: LatLng(r.client.coordinates.lat, r.client.coordinates.lon),
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => ref
                      .read(tourSelectionProvider.notifier)
                      .toggle(r.client.id),
                  child: Icon(
                    selection.contains(r.client.id)
                        ? Icons.check_circle
                        : Icons.location_on,
                    color: selection.contains(r.client.id)
                        ? Colors.green
                        : Colors.blue,
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
