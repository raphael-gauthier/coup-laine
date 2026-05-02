// lib/presentation/map/map_screen.dart
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/design_tokens.dart';
import '../../core/text_search.dart';
import '../../domain/models/client.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../l10n/app_localizations.dart';
import '../../state/map_controller.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;
import '../widgets/app_option_tile.dart';
import '../widgets/map_pins.dart';
import '../widgets/osm_tile_layer.dart';
import 'client_pin_popup.dart';

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

  Color _resolveColor(Client c, ClientStatus status, Settings s) {
    if (c.markerColorHex != null) return _hexToColor(c.markerColorHex!);
    return switch (status) {
      ClientStatus.waiting => _hexToColor(s.markerWaitingColor),
      ClientStatus.scheduled => _hexToColor(s.markerScheduledColor),
      ClientStatus.done => _hexToColor(s.markerDoneColor),
      ClientStatus.noAnimals => _hexToColor(s.markerNoAnimalsColor),
      ClientStatus.banned => _hexToColor(s.markerBannedColor),
      ClientStatus.defaultStatus => _hexToColor(s.markerDefaultColor),
    };
  }

  void _maybeFitToBounds(List<(Client, ClientStatus)> clients, Settings settings) {
    if (_initialFitDone) return;
    final points = <LatLng>[
      LatLng(settings.baseCoordinates.lat, settings.baseCoordinates.lon),
      for (final r in clients) LatLng(r.$1.coordinates.lat, r.$1.coordinates.lon),
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

  void _maybeConsumePendingFocus(List<(Client, ClientStatus)> clients) {
    final pending = ref.read(mapPendingFocusProvider);
    if (pending == null) return;
    final tuple = clients.firstWhereOrNull((r) => r.$1.id == pending);
    if (tuple == null) {
      ref.read(mapPendingFocusProvider.notifier).state = null;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _flyTo(tuple.$1);
      ref.read(mapPendingFocusProvider.notifier).state = null;
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
    final l = AppLocalizations.of(context)!;
    await showFDialog<void>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l.mapLayersDialogTitle),
        body: SizedBox(
          width: 280,
          child: Consumer(
            builder: (context, ref, _) {
              final visible = ref.watch(mapVisibleStatusesProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in [
                    (ClientStatus.defaultStatus, l.settingsMarkerDefault),
                    (ClientStatus.waiting, l.settingsMarkerWaiting),
                    (ClientStatus.scheduled, l.settingsMarkerScheduled),
                    (ClientStatus.done, l.settingsMarkerDone),
                    (ClientStatus.noAnimals, l.settingsMarkerNoAnimals),
                    (ClientStatus.banned, l.settingsMarkerBanned),
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
            child: Text(l.mapLayersDialogClose),
          ),
        ],
      ),
    );
  }

  void _recenterOnVisible(List<(Client, ClientStatus)> visibleClients, Settings settings) {
    final points = <LatLng>[
      LatLng(settings.baseCoordinates.lat, settings.baseCoordinates.lon),
      for (final r in visibleClients) LatLng(r.$1.coordinates.lat, r.$1.coordinates.lon),
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
    final theme = context.theme;
    final clientsAsync = ref.watch(clientsAsyncProvider);
    final settingsAsync = ref.watch(settingsForMapProvider);

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
                _maybeConsumePendingFocus(clients);
                _maybeFitToBounds(clients, settings);
                final visibleStatuses = ref.watch(mapVisibleStatusesProvider);
                final visibleClients = clients
                    .where((r) => visibleStatuses.contains(r.$2))
                    .toList();
                final selectedId = ref.watch(mapSelectedClientIdProvider);
                final selectedClient = selectedId == null
                    ? null
                    : visibleClients.firstWhereOrNull((r) => r.$1.id == selectedId);
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
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                          onTap: (_, __) {
                            if (ref.read(mapSelectedClientIdProvider) != null) {
                              ref.read(mapSelectedClientIdProvider.notifier).state = null;
                            }
                          },
                        ),
                        children: [
                          osmTileLayer(),
                          MarkerLayer(
                            rotate: true,
                            markers: [
                              // Base pin
                              Marker(
                                point: LatLng(
                                  settings.baseCoordinates.lat,
                                  settings.baseCoordinates.lon,
                                ),
                                width: 48,
                                height: 56,
                                alignment: Alignment.bottomCenter,
                                child: MapBasePin(color: theme.colors.primary),
                              ),
                              // Client pins
                              for (final r in visibleClients)
                                Marker(
                                  point: LatLng(
                                    r.$1.coordinates.lat,
                                    r.$1.coordinates.lon,
                                  ),
                                  width: 40,
                                  height: 48,
                                  alignment: Alignment.bottomCenter,
                                  child: GestureDetector(
                                    onTap: () {
                                      final currentSelected = ref.read(mapSelectedClientIdProvider);
                                      if (currentSelected == r.$1.id) {
                                        context.push('/clients/${r.$1.id}');
                                      } else {
                                        ref.read(mapSelectedClientIdProvider.notifier).state = r.$1.id;
                                        _mapController.move(
                                          LatLng(
                                            r.$1.coordinates.lat,
                                            r.$1.coordinates.lon,
                                          ),
                                          _mapController.camera.zoom,
                                        );
                                      }
                                    },
                                    child: MapStatusPin(
                                      color: _resolveColor(r.$1, r.$2, settings),
                                      animalCount: r.$1.animalsTotal,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (selectedClient != null)
                            MarkerLayer(
                              rotate: true,
                              markers: [
                                Marker(
                                  point: LatLng(
                                    selectedClient.$1.coordinates.lat,
                                    selectedClient.$1.coordinates.lon,
                                  ),
                                  width: 300,
                                  height: 200,
                                  alignment: const Alignment(0, -1.4),
                                  child: ClientPinPopup(
                                    client: selectedClient.$1,
                                    status: selectedClient.$2,
                                    onOpenDetail: () {
                                      ref.read(mapSelectedClientIdProvider.notifier).state = null;
                                      context.push('/clients/${selectedClient.$1.id}');
                                    },
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                            const SizedBox(height: AppSpacing.sm),
                            _StatusChipsRow(clients: clients, settings: settings),
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

/// Provider — reads Settings as an AsyncValue, used by MapScreen. Public
/// (et non `_settingsForMapProvider`) pour permettre l'invalidation depuis
/// le restore cloud (`backup_picker_screen._runRestore`) — sans ça, l'onglet
/// Carte (gardé monté via Offstage par le shell route) afficherait l'ancienne
/// adresse de base après une restauration.
final settingsForMapProvider = FutureProvider<Settings?>(
  (ref) => ref.watch(settingsRepositoryProvider).read(),
);

class _SearchOverlay extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<(Client, ClientStatus)> clients;
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
            final q = normalize(query.trim());
            return clients
                .where((r) => matchesClient(r.$1, q))
                .map((r) => r.$1)
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
          const SizedBox(height: AppSpacing.xxs),
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

// Pins extracted to `lib/presentation/widgets/map_pins.dart` so they're
// shared with the proximity Map view (tour creation flow).

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
    final color = switch (status) {
      ClientStatus.defaultStatus => _hex(settings.markerDefaultColor),
      ClientStatus.waiting => _hex(settings.markerWaitingColor),
      ClientStatus.scheduled => _hex(settings.markerScheduledColor),
      ClientStatus.done => _hex(settings.markerDoneColor),
      ClientStatus.noAnimals => _hex(settings.markerNoAnimalsColor),
      ClientStatus.banned => _hex(settings.markerBannedColor),
    };
    return AppOptionTile(
      leading: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: label,
      checked: isOn,
      onChanged: onChanged,
    );
  }
}

/// Floating row of status chips above the map. Shows a compact count per
/// status (only statuses with ≥1 client are rendered). Tapping a chip
/// toggles it in `mapVisibleStatusesProvider` — the marker layer filters
/// accordingly.
class _StatusChipsRow extends ConsumerWidget {
  final List<(Client, ClientStatus)> clients;
  final Settings settings;
  const _StatusChipsRow({required this.clients, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final visible = ref.watch(mapVisibleStatusesProvider);

    final counts = <ClientStatus, int>{
      for (final s in ClientStatus.values) s: 0,
    };
    for (final r in clients) {
      counts[r.$2] = (counts[r.$2] ?? 0) + 1;
    }

    final entries = ClientStatus.values
        .where((s) => (counts[s] ?? 0) > 0)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final s in entries)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final next = {...visible};
                  if (next.contains(s)) {
                    next.remove(s);
                  } else {
                    next.add(s);
                  }
                  ref.read(mapVisibleStatusesProvider.notifier).state = next;
                },
                child: _StatusChip(
                  status: s,
                  count: counts[s]!,
                  active: visible.contains(s),
                  label: _statusLabelForChip(l, s),
                  color: _statusColor(s, settings),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ClientStatus s, Settings settings) {
    final hex = switch (s) {
      ClientStatus.defaultStatus => settings.markerDefaultColor,
      ClientStatus.waiting => settings.markerWaitingColor,
      ClientStatus.scheduled => settings.markerScheduledColor,
      ClientStatus.done => settings.markerDoneColor,
      ClientStatus.noAnimals => settings.markerNoAnimalsColor,
      ClientStatus.banned => settings.markerBannedColor,
    };
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }
}

String _statusLabelForChip(AppLocalizations l, ClientStatus s) => switch (s) {
      ClientStatus.defaultStatus => l.clientStatusDefault,
      ClientStatus.waiting => l.clientStatusWaiting,
      ClientStatus.scheduled => l.clientStatusScheduled,
      ClientStatus.done => l.clientStatusDone,
      ClientStatus.noAnimals => l.clientStatusNoAnimals,
      ClientStatus.banned => l.clientStatusBanned,
    };

class _StatusChip extends StatelessWidget {
  final ClientStatus status;
  final int count;
  final bool active;
  final String label;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.count,
    required this.active,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final dur = const Duration(milliseconds: 120);
    return AnimatedContainer(
      duration: dur,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: active ? theme.colors.card : theme.colors.muted,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        border: Border.all(
          color: active ? color : theme.colors.border,
          width: active ? 1.5 : AppSizes.hairlineBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: dur,
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? color : theme.colors.mutedForeground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          AnimatedDefaultTextStyle(
            duration: dur,
            style: theme.typography.sm.copyWith(
              color: active ? theme.colors.foreground : theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
            child: Text('$count'),
          ),
          const SizedBox(width: AppSpacing.xxs),
          AnimatedDefaultTextStyle(
            duration: dur,
            style: theme.typography.xs.copyWith(
              color: active ? theme.colors.foreground : theme.colors.mutedForeground,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
