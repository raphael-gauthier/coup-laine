// lib/presentation/tours/tours_list_screen.dart
import 'package:flutter/material.dart' show ButtonSegment, Material, MaterialType, RefreshIndicator, SegmentedButton;
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/tour.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_list_tile.dart';

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
      child: Material(
        type: MaterialType.transparency,
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
                    padding: AppSizes.rootScreenPadding.copyWith(bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page heading
                        Text(
                          l.toursListTitle,
                          style: theme.typography.xl3.copyWith(
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
                    hasScrollBody: false,
                    child: AppEmptyState(
                      illustrationAsset: 'assets/illustrations/empty-tours.svg',
                      title: l.emptyToursTitle,
                      body: l.emptyToursBody,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _TourTile(tour: list[i]),
                    ),
                  ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}

class _TourTile extends StatelessWidget {
  final Tour tour;
  const _TourTile({required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isCompleted = tour.status == TourStatus.completed;

    final dateLabel = DateFormat('EEE d MMM yyyy', 'fr').format(tour.plannedDate);
    final km = (tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final driveMin = tour.totalDriveSeconds ~/ 60;

    final prefixBg = isCompleted ? theme.colors.primary : theme.colors.secondary;
    final prefixIcon = isCompleted ? FIcons.calendarCheck : FIcons.calendar;
    final prefixFg = isCompleted ? theme.colors.primaryForeground : theme.colors.secondaryForeground;

    return AppListTile(
      prefix: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: prefixBg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(prefixIcon, color: prefixFg, size: 18),
      ),
      title: dateLabel,
      subtitle: '$km km · $driveMin min',
      suffix: isCompleted ? AppBadge.completed(context) : AppBadge.planned(context),
      onPress: () => context.push('/tours/${tour.id}'),
    );
  }
}
