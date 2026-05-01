// lib/presentation/tours/tours_list_screen.dart
import 'package:flutter/material.dart' show RefreshIndicator;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../domain/models/tour.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_header.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_option_tile.dart';
import '../widgets/app_stat.dart';

final _visibleTourStatusesProvider = StateProvider<Set<TourStatus>>(
  (_) => TourStatus.values.toSet(),
);

final toursAsyncProvider = FutureProvider<List<Tour>>((ref) {
  return ref.watch(tourRepositoryProvider).listAll();
});

class ToursListScreen extends ConsumerWidget {
  const ToursListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final visible = ref.watch(_visibleTourStatusesProvider);
    final async = ref.watch(toursAsyncProvider);

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            async.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final planned =
                    all.where((t) => t.status == TourStatus.planned).toList();
                final list =
                    all.where((t) => visible.contains(t.status)).toList();

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(toursAsyncProvider),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: AppHeader(
                          title: l.toursListTitle,
                          subtitle: l.toursStatsFmt(all.length, planned.length),
                          showBackButton: false,
                          actions: [
                            AppHeaderAction(
                              icon: FIcons.listFilter,
                              label: 'Filtrer',
                              onPress: () =>
                                  _TourStatusFilterButton.openFilterDialog(
                                      context, ref, l),
                            ),
                          ],
                        ),
                      ),
                      if (visible.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                'Aucun statut sélectionné',
                                style: context.theme.typography.sm,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmptyState(
                            illustrationAsset:
                                'assets/illustrations/empty-tours.svg',
                            title: l.emptyToursTitle,
                            body: l.emptyToursBody,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, AppSizes.bottomScrollPadding),
                          sliver: SliverList.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) => _TourTile(tour: list[i]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _NewTourFab(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square icon button placed next to the page title that opens a dialog
/// of tour-status checkboxes. A small dot in the corner signals when the
/// filter is non-default (i.e. at least one status hidden).
class _TourStatusFilterButton extends ConsumerWidget {
  const _TourStatusFilterButton();

  static Future<void> openFilterDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    await showFDialog<void>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l.clientsFilterByStatus),
        body: SizedBox(
          width: 280,
          child: Consumer(
            builder: (context, ref, _) {
              final visible = ref.watch(_visibleTourStatusesProvider);
              final theme = context.theme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in TourStatus.values)
                    _TourStatusToggleRow(
                      status: s,
                      label: _statusLabel(l, s),
                      color: s == TourStatus.completed
                          ? theme.colors.primary
                          : theme.colors.secondary,
                      isOn: visible.contains(s),
                      onChanged: (on) {
                        final next = {...visible};
                        if (on) {
                          next.add(s);
                        } else {
                          next.remove(s);
                        }
                        ref
                            .read(_visibleTourStatusesProvider.notifier)
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kept for backward compatibility — unused after AppHeader actions migration.
    return const SizedBox.shrink();
  }
}

String _statusLabel(AppLocalizations l, TourStatus s) => switch (s) {
      TourStatus.planned => l.toursStatusPlanned,
      TourStatus.completed => l.toursStatusCompleted,
    };

/// Single row inside the tour status filter dialog. Visual unifié v3 :
/// dot coloré 16dp + label + checkbox carré 22dp via `AppOptionTile`.
class _TourStatusToggleRow extends StatelessWidget {
  final TourStatus status;
  final String label;
  final Color color;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const _TourStatusToggleRow({
    required this.status,
    required this.label,
    required this.color,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppOptionTile(
      leading: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: label,
      checked: isOn,
      onChanged: onChanged,
    );
  }
}

class _TourTile extends StatelessWidget {
  final Tour tour;
  const _TourTile({required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final date = tour.plannedDate;
    final km = (tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final driveMin = tour.totalDriveSeconds ~/ 60;
    final title =
        'Tournée du ${DateFormat('d MMM', 'fr').format(date)}';

    final prefix = Container(
      width: 40,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('d').format(date),
            style: theme.typography.xl
                .copyWith(color: theme.colors.foreground),
          ),
          Text(
            DateFormat('MMM', 'fr').format(date),
            style: theme.typography.xs
                .copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );

    final metadata = Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xxs,
      children: [
        AppStat(icon: FIcons.route, value: '$km km'),
        AppStat(icon: FIcons.clock, value: formatDuration(driveMin)),
        AppStat(value: formatEuros(tour.totalTravelFeeCents)),
        tour.status == TourStatus.completed
            ? AppBadge.completed(context)
            : AppBadge.planned(context),
      ],
    );

    return AppListTile(
      variant: AppListTileVariant.rich,
      prefix: prefix,
      title: title,
      metadata: metadata,
      suffix: const Icon(FIcons.chevronRight),
      onTap: () => context.push('/tours/${tour.id}'),
    );
  }
}

class _NewTourFab extends StatelessWidget {
  const _NewTourFab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppFAB(
      icon: FIcons.plus,
      label: 'Tournée',
      extended: true,
      onPress: () => _showCreateSheet(context, l),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, AppLocalizations l) async {
    await showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (sheetCtx) {
        final theme = sheetCtx.theme;
        return ColoredBox(
          color: theme.colors.background,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l.newTourSheetTitle,
                    style: theme.typography.lg
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                FButton(
                  prefix: const Icon(FIcons.users),
                  onPress: () {
                    Navigator.of(sheetCtx).pop();
                    context.push('/tours/new/manual');
                  },
                  child: Text(l.newTourSheetManual),
                ),
                const SizedBox(height: AppSpacing.xs),
                FButton(
                  variant: FButtonVariant.outline,
                  prefix: const Icon(FIcons.route),
                  onPress: () {
                    Navigator.of(sheetCtx).pop();
                    context.push('/tours/new/optimized');
                  },
                  child: Text(l.newTourSheetOptimized),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
