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

class WaitingClientsMultiPicker extends ConsumerStatefulWidget {
  final Set<int> initialSelection;
  final ValueChanged<Set<int>> onSelectionChanged;

  const WaitingClientsMultiPicker({
    super.key,
    required this.initialSelection,
    required this.onSelectionChanged,
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
        if (data.eligible.isEmpty) {
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
                      clients: data.eligible,
                      selection: _selection,
                      query: _query,
                      onQueryChanged: (q) => setState(() => _query = q),
                      onToggle: _toggle,
                    ),
                  ),
                  FTabEntry(
                    label: Text(l.manualPickerTabMap),
                    child: _MapTab(
                      clients: data.eligible,
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
  }
}

class _ListTab extends StatefulWidget {
  final List<Client> clients;
  final Set<int> selection;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onToggle;
  const _ListTab({
    required this.clients,
    required this.selection,
    required this.query,
    required this.onQueryChanged,
    required this.onToggle,
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final c = filtered[i];
                final selected = widget.selection.contains(c.id);
                return FTile(
                  prefix:
                      Icon(FIcons.mapPin, color: theme.colors.mutedForeground),
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
              },
            ),
          ),
        ),
      ],
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
