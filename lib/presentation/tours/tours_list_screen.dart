// lib/presentation/tours/tours_list_screen.dart
import 'package:flutter/material.dart' show RefreshIndicator, SegmentedButton, ButtonSegment;
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/tour.dart';
import '../../state/providers.dart';

enum _Filter { all, planned, completed }

final _filterProvider = StateProvider<_Filter>((_) => _Filter.all);

final toursAsyncProvider = FutureProvider<List<Tour>>((ref) {
  return ref.watch(tourRepositoryProvider).listAll();
});

class ToursListScreen extends ConsumerWidget {
  const ToursListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final filter = ref.watch(_filterProvider);
    final async = ref.watch(toursAsyncProvider);

    return FScaffold(
      child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final planned = all.where((t) => t.status == TourStatus.planned).toList();
          final completed = all.where((t) => t.status == TourStatus.completed).toList();
          final list = switch (filter) {
            _Filter.planned => planned,
            _Filter.completed => completed,
            _Filter.all => all,
          };

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(toursAsyncProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page heading
                        Text(
                          l.toursListTitle,
                          style: theme.typography.xl3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Stats row
                        Text(
                          l.toursStatsFmt(all.length, planned.length),
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Filter
                        SegmentedButton<_Filter>(
                          segments: [
                            ButtonSegment(value: _Filter.all, label: Text(l.toursFilterAll)),
                            ButtonSegment(value: _Filter.planned, label: Text(l.toursFilterPlanned)),
                            ButtonSegment(value: _Filter.completed, label: Text(l.toursFilterCompleted)),
                          ],
                          selected: {filter},
                          onSelectionChanged: (s) =>
                              ref.read(_filterProvider.notifier).state = s.first,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FIcons.route,
                              size: 56,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l.emptyToursTitle,
                              style: theme.typography.xl.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.emptyToursBody,
                              textAlign: TextAlign.center,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (_, i) => _TourTile(tour: list[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TourTile extends StatelessWidget {
  final Tour tour;
  const _TourTile({required this.tour});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final isCompleted = tour.status == TourStatus.completed;

    final dateLabel = DateFormat('EEE d MMM yyyy', 'fr').format(tour.plannedDate);
    final km = (tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final driveMin = tour.totalDriveSeconds ~/ 60;

    return FTile(
      prefix: Icon(
        isCompleted ? FIcons.calendarCheck : FIcons.calendar,
        color: isCompleted ? theme.colors.primary : theme.colors.mutedForeground,
      ),
      title: Text(
        dateLabel,
        style: theme.typography.md.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$km km · $driveMin min',
        style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
      ),
      suffix: FBadge(
        variant: isCompleted ? FBadgeVariant.secondary : FBadgeVariant.primary,
        child: Text(isCompleted ? l.toursStatusCompleted : l.toursStatusPlanned),
      ),
      onPress: () => context.push('/tours/${tour.id}'),
    );
  }
}
