// lib/presentation/proximity/proximity_map_view.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../state/providers.dart';
import '../../state/proximity_controller.dart';
import '../widgets/map_pins.dart';
import '../widgets/osm_tile_layer.dart';

class ProximityMapView extends ConsumerWidget {
  final int pivotId;
  const ProximityMapView({super.key, required this.pivotId});

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final pivot = ref.watch(pivotClientProvider(pivotId)).value;
    final results = ref.watch(proximityResultsProvider).value ?? const [];
    final settings = ref.watch(settingsRepositoryFutureProvider).value;
    if (pivot == null || settings == null) {
      return const Center(child: FCircularProgress());
    }
    final pivotLatLng = LatLng(pivot.coordinates.lat, pivot.coordinates.lon);
    final selection = ref.watch(tourSelectionProvider);

    // All results from `FindNearbyClients` are filtered to waiting status,
    // so we use the "waiting" marker color for them — except when the client
    // overrides via `markerColorHex`.
    final waitingColor = _hexToColor(settings.markerWaitingColor);

    return FlutterMap(
      options: MapOptions(
        initialCenter: pivotLatLng,
        initialZoom: 11,
      ),
      children: [
        osmTileLayer(),
        MarkerLayer(
          rotate: true,
          markers: [
            // Pivot — drop-pin distinctif (icône target en lieu de house pour
            // signaler que c'est l'ancre de recherche, pas la base maison).
            Marker(
              point: pivotLatLng,
              width: 48,
              height: 56,
              alignment: Alignment.bottomCenter,
              child: MapBasePin(
                color: theme.colors.primary,
                icon: FIcons.target,
              ),
            ),
            // Candidats à proximité (tous en statut waiting).
            for (final r in results)
              Marker(
                point: LatLng(
                  r.client.coordinates.lat,
                  r.client.coordinates.lon,
                ),
                width: 48,
                height: 50,
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () => ref
                      .read(tourSelectionProvider.notifier)
                      .toggle(r.client.id),
                  child: MapStatusPin(
                    color: r.client.markerColorHex != null
                        ? _hexToColor(r.client.markerColorHex!)
                        : waitingColor,
                    animalCount: r.client.animalsTotal,
                    selected: selection.contains(r.client.id),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
