// lib/presentation/tours/tours_list_screen.dart
import 'package:flutter/material.dart' show Material, MaterialType, RefreshIndicator;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
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
    final theme = context.theme;
    final visible = ref.watch(_visibleTourStatusesProvider);
    final async = ref.watch(toursAsyncProvider);

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Material(
              type: MaterialType.transparency,
              child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final planned = all.where((t) => t.status == TourStatus.planned).toList();
          final list = all.where((t) => visible.contains(t.status)).toList();

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
                        // Heading row: title + filter button on the right
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.toursListTitle,
                                    style: theme.typography.xl3.copyWith(
                                      color: theme.colors.foreground,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    l.toursStatsFmt(all.length, planned.length),
                                    style: theme.typography.sm.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const _TourStatusFilterButton(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
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
                          style: theme.typography.sm,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else if (list.isEmpty)
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSizes.bottomScrollPadding),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final visible = ref.watch(_visibleTourStatusesProvider);
    final hasActiveFilter = visible.length != TourStatus.values.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFilterDialog(context, ref),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: theme.colors.border),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(FIcons.listFilter, color: theme.colors.foreground, size: 20),
            if (hasActiveFilter)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colors.card, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterDialog(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
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
}

String _statusLabel(AppLocalizations l, TourStatus s) => switch (s) {
      TourStatus.planned => l.toursStatusPlanned,
      TourStatus.completed => l.toursStatusCompleted,
    };

/// Single row inside the tour status filter dialog. Mirrors the clients
/// list filter dialog: 16 px colored dot, label, trailing FSwitch.
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
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: theme.typography.md)),
          FSwitch(value: isOn, onChange: onChanged),
        ],
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

    return FTile(
      prefix: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: prefixBg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(prefixIcon, color: prefixFg, size: 18),
      ),
      title: Text(dateLabel),
      subtitle: Text('$km km · $driveMin min'),
      suffix: isCompleted ? AppBadge.completed(context) : AppBadge.planned(context),
      onPress: () => context.push('/tours/${tour.id}'),
    );
  }
}

class _NewTourFab extends StatelessWidget {
  const _NewTourFab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return GestureDetector(
      onTap: () => _open(context, l),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colors.foreground.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(FIcons.plus,
            color: theme.colors.primaryForeground, size: 28),
      ),
    );
  }

  Future<void> _open(BuildContext context, AppLocalizations l) async {
    await showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (sheetCtx) {
        final theme = sheetCtx.theme;
        return Padding(
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
              FTile(
                prefix: const Icon(FIcons.users),
                title: Text(l.newTourSheetManual),
                subtitle: Text(l.newTourSheetManualSubtitle),
                onPress: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/tours/new/manual');
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              FTile(
                prefix: const Icon(FIcons.route),
                title: Text(l.newTourSheetOptimized),
                subtitle: Text(l.newTourSheetOptimizedSubtitle),
                onPress: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/tours/new/optimized');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
