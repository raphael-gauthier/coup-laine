// lib/presentation/proximity/proximity_list_view.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/proximity_controller.dart';

class ProximityListView extends ConsumerWidget {
  const ProximityListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(proximityResultsProvider);
    final selection = ref.watch(tourSelectionProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (results) {
        if (results.isEmpty) {
          return Center(child: Text(l.proximityNoneInRadius));
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = results[i];
            final selected = selection.contains(r.client.id);
            return CheckboxListTile(
              value: selected,
              onChanged: (_) => ref
                  .read(tourSelectionProvider.notifier)
                  .toggle(r.client.id),
              title: Text(r.client.name),
              subtitle: Text(
                '${r.client.city} · ${l.proximityDistanceFmt(
                  (r.distanceMeters / 1000).toStringAsFixed(1),
                  (r.durationSeconds / 60).round(),
                )} · ${r.client.sheepCount} moutons',
              ),
            );
          },
        );
      },
    );
  }
}
