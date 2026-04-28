// lib/presentation/map/map_screen.dart
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models/client.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _initialFitDone = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  Color _resolveColor(Client c, Settings s) {
    if (c.markerColorHex != null) return _hexToColor(c.markerColorHex!);
    return switch (c.status) {
      ClientStatus.recompute => _hexToColor(s.markerRecomputeColor),
      ClientStatus.waiting => _hexToColor(s.markerWaitingColor),
      ClientStatus.overdue => _hexToColor(s.markerOverdueColor),
      ClientStatus.defaultStatus => _hexToColor(s.markerDefaultColor),
    };
  }

  void _maybeFitToBounds(List<Client> clients, Settings settings) {
    if (_initialFitDone) return;
    final points = <LatLng>[
      LatLng(settings.baseCoordinates.lat, settings.baseCoordinates.lon),
      for (final c in clients) LatLng(c.coordinates.lat, c.coordinates.lon),
    ];
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(points);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
      _initialFitDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsAsyncProvider);
    final settingsAsync = ref.watch(_settingsForMapProvider);

    return FScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: clientsAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (clients) {
            return settingsAsync.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (e, _) => Center(child: Text('$e')),
              data: (settings) {
                if (settings == null) {
                  return const Center(child: Text('Settings introuvables'));
                }
                _maybeFitToBounds(clients, settings);
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      settings.baseCoordinates.lat,
                      settings.baseCoordinates.lon,
                    ),
                    initialZoom: 11,
                    minZoom: 6,
                    maxZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'fr.coupelaine',
                    ),
                    MarkerLayer(
                      markers: [
                        // Base star
                        Marker(
                          point: LatLng(
                            settings.baseCoordinates.lat,
                            settings.baseCoordinates.lon,
                          ),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(
                            FIcons.star,
                            color: _hexToColor(settings.markerDefaultColor),
                            size: 36,
                          ),
                        ),
                        // Client pins
                        for (final c in clients)
                          Marker(
                            point: LatLng(
                              c.coordinates.lat,
                              c.coordinates.lon,
                            ),
                            width: 32,
                            height: 40,
                            alignment: Alignment.bottomCenter,
                            child: Icon(
                              FIcons.mapPin,
                              color: _resolveColor(c, settings),
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Local provider — reads Settings as an AsyncValue, used only by MapScreen.
final _settingsForMapProvider = FutureProvider<Settings?>(
  (ref) => ref.watch(settingsRepositoryProvider).read(),
);
