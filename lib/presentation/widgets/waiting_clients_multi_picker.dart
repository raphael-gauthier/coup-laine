import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import '../../core/text_search.dart';
import '../../domain/models/client.dart';
import '../../state/providers.dart';
import 'app_empty_state.dart';

/// One-shot loader for a fixed set of client ids. Used by
/// [WaitingClientsMultiPicker] to surface clients that don't satisfy the
/// "waiting" filter but must remain selectable (e.g. tour edit mode).
///
/// The key is a sorted, comma-joined string of ids — Sets and Lists in Dart
/// have identity equality, which would re-trigger the family on every
/// rebuild even when the contents are unchanged.
final _clientsByIdsProvider = FutureProvider.autoDispose
    .family<List<Client>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return const <Client>[];
  final ids = idsKey.split(',').map(int.parse);
  final repo = ref.watch(clientRepositoryProvider);
  final out = <Client>[];
  for (final id in ids) {
    final c = await repo.findById(id);
    if (c != null) out.add(c);
  }
  return out;
});

class WaitingClientsMultiPicker extends ConsumerStatefulWidget {
  final Set<int> initialSelection;
  final ValueChanged<Set<int>> onSelectionChanged;

  /// Clients listed here are forced into the picker even when they don't
  /// satisfy the "waiting" filter — used by tour edit mode so a client that
  /// is already on the tour stays visible (and therefore deselectable) even
  /// if its status has since moved out of `waiting`.
  final Set<int> alwaysIncludeIds;

  /// Subset of client ids (from `eligible` + `alwaysIncludeIds`) considered
  /// "nearby" to the current context (e.g. tour stops). When non-empty, the
  /// list-tab renders two sections: "Suggérés à proximité" then "Autres
  /// clients en attente". Map-tab is unaffected.
  final Set<int> nearbyIds;

  const WaitingClientsMultiPicker({
    super.key,
    required this.initialSelection,
    required this.onSelectionChanged,
    this.alwaysIncludeIds = const {},
    this.nearbyIds = const {},
  });

  @override
  ConsumerState<WaitingClientsMultiPicker> createState() =>
      _WaitingClientsMultiPickerState();
}

class _WaitingClientsMultiPickerState
    extends ConsumerState<WaitingClientsMultiPicker> {
  late Set<int> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = {...widget.initialSelection};
  }

  void _toggle(int id) {
    setState(() {
      if (!_selection.add(id)) _selection.remove(id);
    });
    widget.onSelectionChanged({..._selection});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(waitingPickerCandidatesProvider);
    return async.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        // Pull in clients that must stay visible even if they're not waiting.
        final extraIds =
            widget.alwaysIncludeIds.difference(data.eligible.map((c) => c.id).toSet());
        final extraKey = (extraIds.toList()..sort()).join(',');
        final extraAsync = extraIds.isEmpty
            ? const AsyncData<List<Client>>(<Client>[])
            : ref.watch(_clientsByIdsProvider(extraKey));
        return extraAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (extras) {
            final eligible = [...extras, ...data.eligible];
            if (eligible.isEmpty) {
              return AppEmptyState(
                illustrationAsset: 'assets/illustrations/empty-clients.svg',
                title: l.manualPickerEmptyTitle,
                body: l.manualPickerEmptyBody,
              );
            }
            return Column(
              children: [
                if (data.excludedCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                    child: FCard.raw(
                      child: Padding(
                        padding: AppSizes.cardPadding,
                        child: Text(
                          l.manualPickerExcludedFmt(data.excludedCount),
                          style: context.theme.typography.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: FTabs(
                    expands: true,
                    children: [
                      FTabEntry(
                        label: Text(l.manualPickerTabList),
                        child: _ListTab(
                          clients: eligible,
                          selection: _selection,
                          query: _query,
                          onQueryChanged: (q) => setState(() => _query = q),
                          onToggle: _toggle,
                          nearbyIds: widget.nearbyIds,
                        ),
                      ),
                      FTabEntry(
                        label: Text(l.manualPickerTabMap),
                        child: _MapTab(
                          clients: eligible,
                          selection: _selection,
                          onToggle: _toggle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ListTab extends StatefulWidget {
  final List<Client> clients;
  final Set<int> selection;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onToggle;
  final Set<int> nearbyIds;
  const _ListTab({
    required this.clients,
    required this.selection,
    required this.query,
    required this.onQueryChanged,
    required this.onToggle,
    required this.nearbyIds,
  });

  @override
  State<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<_ListTab> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final norm = normalize(widget.query.trim());
    final filtered = norm.isEmpty
        ? widget.clients
        : widget.clients.where((c) => matchesClient(c, norm)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: FTextField(
            control: FTextFieldControl.managed(
              controller: _controller,
              onChange: (v) => widget.onQueryChanged(v.text),
            ),
            hint: l.manualPickerSearchHint,
          ),
        ),
        Expanded(
          child: Material(
            type: MaterialType.transparency,
            child: Builder(builder: (_) {
              final hasSections = widget.nearbyIds.isNotEmpty;
              if (!hasSections) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _buildClientTile(context, filtered[i]),
                );
              }
              final nearby = [
                for (final c in filtered)
                  if (widget.nearbyIds.contains(c.id)) c,
              ];
              final others = [
                for (final c in filtered)
                  if (!widget.nearbyIds.contains(c.id)) c,
              ];
              final l = AppLocalizations.of(context)!;
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  if (nearby.isNotEmpty) ...[
                    _SectionHeader(label: l.pickerSectionNearby, theme: theme),
                    for (final c in nearby) ...[
                      _buildClientTile(context, c),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                  if (others.isNotEmpty) ...[
                    _SectionHeader(label: l.pickerSectionOthers, theme: theme),
                    for (final c in others) ...[
                      _buildClientTile(context, c),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildClientTile(BuildContext context, Client c) {
    final theme = context.theme;
    final selected = widget.selection.contains(c.id);
    return FTile(
      prefix: Icon(FIcons.mapPin, color: theme.colors.mutedForeground),
      title: Text(c.name),
      subtitle: Text(c.city),
      suffix: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? theme.colors.primary : null,
          border: selected
              ? null
              : Border.all(color: theme.colors.border, width: 2),
        ),
        child: selected
            ? Icon(FIcons.check,
                color: theme.colors.primaryForeground, size: 16)
            : null,
      ),
      onPress: () => widget.onToggle(c.id),
    );
  }
}

class _MapTab extends StatelessWidget {
  final List<Client> clients;
  final Set<int> selection;
  final ValueChanged<int> onToggle;
  const _MapTab({
    required this.clients,
    required this.selection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (clients.isEmpty) {
      return const SizedBox.shrink();
    }
    final centre = clients.first;
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centre.coordinates.lat, centre.coordinates.lon),
        initialZoom: 9,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'fr.raphaelgauthier.couplaine',
        ),
        MarkerLayer(
          markers: [
            for (final c in clients)
              Marker(
                point: LatLng(c.coordinates.lat, c.coordinates.lon),
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => onToggle(c.id),
                  child: Icon(
                    FIcons.mapPin,
                    color: selection.contains(c.id)
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final FThemeData theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        label,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
