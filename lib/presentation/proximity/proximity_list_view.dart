// lib/presentation/proximity/proximity_list_view.dart
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../state/proximity_controller.dart';

class ProximityListView extends ConsumerWidget {
  const ProximityListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(proximityResultsProvider);
    final selection = ref.watch(tourSelectionProvider);

    return async.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text('$e')),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FIcons.compass,
                  size: 40,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(height: 12),
                Text(
                  l.proximityNoneInRadius,
                  style: theme.typography.sm
                      .copyWith(color: theme.colors.mutedForeground),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const FDivider(),
          itemBuilder: (_, i) {
            final r = results[i];
            final selected = selection.contains(r.client.id);
            return FTile(
              prefix: Icon(
                FIcons.mapPin,
                color: theme.colors.mutedForeground,
              ),
              title: Text(
                r.client.name,
                style: theme.typography.sm
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${r.client.city} · ${l.proximityDistanceFmt(
                  (r.distanceMeters / 1000).toStringAsFixed(1),
                  (r.durationSeconds / 60).round(),
                )} · ${r.client.sheepCount} moutons',
              ),
              suffix: Icon(
                selected ? FIcons.check : FIcons.circle,
                color: selected
                    ? theme.colors.primary
                    : theme.colors.mutedForeground,
              ),
              onPress: () =>
                  ref.read(tourSelectionProvider.notifier).toggle(r.client.id),
            );
          },
        );
      },
    );
  }
}
