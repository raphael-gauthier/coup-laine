// lib/presentation/proximity/proximity_list_view.dart
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../state/proximity_controller.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_list_tile.dart';

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
            child: AppEmptyState(
              illustrationAsset: 'assets/illustrations/empty-clients.svg',
              title: l.proximityNoneInRadius,
              body: l.proximityNoneInRadiusBody,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final r = results[i];
            final selected = selection.contains(r.client.id);
            return AppListTile(
              prefix: Icon(FIcons.mapPin, color: theme.colors.mutedForeground),
              title: r.client.name,
              subtitle: '${r.client.city} · ${l.proximityDistanceFmt(
                (r.distanceMeters / 1000).toStringAsFixed(1),
                (r.durationSeconds / 60).round(),
              )} · ${r.client.sheepCount} moutons',
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
              onPress: () =>
                  ref.read(tourSelectionProvider.notifier).toggle(r.client.id),
            );
          },
        );
      },
    );
  }
}
