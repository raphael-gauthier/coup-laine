// lib/presentation/map/map_screen.dart
import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../state/map_controller.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;

String _removeAccents(String s) {
  const tr = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y',
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'Ç': 'C',
    'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
    'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Ö': 'O',
    'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
  };
  final buf = StringBuffer();
  for (final ch in s.runes) {
    final c = String.fromCharCode(ch);
    buf.write(tr[c] ?? c);
  }
  return buf.toString();
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _initialFitDone = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
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

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(mapSearchQueryProvider.notifier).state = q;
    });
  }

  void _flyTo(Client c) {
    _mapController.move(
      LatLng(c.coordinates.lat, c.coordinates.lon),
      14,
    );
    ref.read(mapSelectedClientIdProvider.notifier).state = c.id;
    _searchCtrl.clear();
    ref.read(mapSearchQueryProvider.notifier).state = '';
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openLayersPanel(BuildContext context, Settings settings) async {
    await showFDialog<void>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: const Text('Afficher les marqueurs'),
        body: SizedBox(
          width: 280,
          child: Consumer(
            builder: (context, ref, _) {
              final visible = ref.watch(mapVisibleStatusesProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in const [
                    (ClientStatus.defaultStatus, 'Par défaut'),
                    (ClientStatus.waiting, 'En attente'),
                    (ClientStatus.overdue, 'En retard'),
                    (ClientStatus.recompute, 'À recalculer'),
                  ])
                    _LayerToggleRow(
                      status: entry.$1,
                      label: entry.$2,
                      settings: settings,
                      isOn: visible.contains(entry.$1),
                      onChanged: (on) {
                        final next = {...visible};
                        if (on) {
                          next.add(entry.$1);
                        } else {
                          next.remove(entry.$1);
                        }
                        ref
                            .read(mapVisibleStatusesProvider.notifier)
                            .state = next;
                      },
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _recenterOnVisible(List<Client> visibleClients, Settings settings) {
    final points = <LatLng>[
      LatLng(settings.baseCoordinates.lat, settings.baseCoordinates.lon),
      for (final c in visibleClients) LatLng(c.coordinates.lat, c.coordinates.lon),
    ];
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
      ),
    );
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
                final visibleStatuses = ref.watch(mapVisibleStatusesProvider);
                final visibleClients = clients
                    .where((c) => visibleStatuses.contains(c.status))
                    .toList();
                return SafeArea(
                  child: Stack(
                    children: [
                      FlutterMap(
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
                              for (final c in visibleClients)
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
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SearchOverlay(
                                controller: _searchCtrl,
                                onChanged: _onSearchChanged,
                                clients: clients,
                                onPicked: _flyTo,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              children: [
                                _MapIconButton(
                                  icon: FIcons.layers,
                                  onPress: () => _openLayersPanel(context, settings),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _MapIconButton(
                                  icon: FIcons.locate,
                                  onPress: () => _recenterOnVisible(visibleClients, settings),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

class _SearchOverlay extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Client> clients;
  final ValueChanged<Client> onPicked;

  const _SearchOverlay({
    required this.controller,
    required this.onChanged,
    required this.clients,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(mapSearchQueryProvider);

    final results = query.trim().isEmpty
        ? const <Client>[]
        : () {
            final q = _removeAccents(query.toLowerCase());
            return clients
                .where((c) =>
                    _removeAccents(c.name.toLowerCase()).contains(q))
                .take(5)
                .toList();
          }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FCard.raw(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: controller,
                onChange: (v) => onChanged(v.text),
              ),
              hint: 'Rechercher un client…',
            ),
          ),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 4),
          FCard.raw(
            child: Column(
              children: [
                for (final c in results)
                  FTile(
                    title: Text(c.name),
                    subtitle: Text(c.city),
                    onPress: () => onPicked(c),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;

  const _MapIconButton({required this.icon, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: theme.colors.foreground, size: 20),
      ),
    );
  }
}

class _LayerToggleRow extends StatelessWidget {
  final ClientStatus status;
  final String label;
  final Settings settings;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const _LayerToggleRow({
    required this.status,
    required this.label,
    required this.settings,
    required this.isOn,
    required this.onChanged,
  });

  Color _hex(String h) {
    final cleaned = h.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = switch (status) {
      ClientStatus.defaultStatus => _hex(settings.markerDefaultColor),
      ClientStatus.waiting => _hex(settings.markerWaitingColor),
      ClientStatus.overdue => _hex(settings.markerOverdueColor),
      ClientStatus.recompute => _hex(settings.markerRecomputeColor),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.typography.md),
          ),
          FSwitch(value: isOn, onChange: onChanged),
        ],
      ),
    );
  }
}
