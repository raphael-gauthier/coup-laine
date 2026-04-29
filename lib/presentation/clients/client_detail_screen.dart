// lib/presentation/clients/client_detail_screen.dart
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import 'client_actions.dart';
import '../../domain/models/client.dart';
import '../../domain/use_cases/client_status.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_hero_card.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import 'clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;

final _clientByIdProvider =
    FutureProvider.family<(Client, ClientStatus)?, int>((ref, id) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  return ref.watch(clientRepositoryProvider).findByIdWithStatus(id, seasonStart);
});

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientByIdProvider(clientId));
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(
          title: Text(async.value?.$1.name ?? '...'),
          suffixes: [
            FButton.icon(
              child: const Icon(FIcons.pencil),
              onPress: () => context.push('/clients/$clientId/edit'),
            ),
            FButton.icon(
              child: const Icon(FIcons.trash),
              onPress: () => _confirmDelete(context, ref, l),
            ),
          ],
        ),
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (record) => record == null
              ? const SizedBox.shrink()
              : _Body(client: record.$1, status: record.$2),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        body: Text(l.clientDetailDeleteConfirm),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(l.clientDetailDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(clientRepositoryProvider).delete(clientId);
      await ref.read(distanceMatrixRepositoryProvider).deleteForClient(clientId);
      ref.invalidate(_clientByIdProvider(clientId));
      ref.invalidate(clientsAsyncProvider);
      ref.invalidate(clientsPendingProvider);
      if (context.mounted) context.pop();
    }
  }
}

class _Body extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  const _Body({required this.client, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    final lastShearingText = client.lastShearingDate == null
        ? l.clientsLastShearingNever
        : l.clientsLastShearingFmt(
            DateFormat('dd/MM/yyyy').format(client.lastShearingDate!),
          );

    final subtitle = client.minutesPerSheepOverride != null
        ? '$lastShearingText · ${client.minutesPerSheepOverride} min/mouton'
        : lastShearingText;

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card: sheep count
          AppHeroCard(
            badge: AppBadge.fromStatus(
              context,
              status: status,
              label: _statusLabel(l, status),
            ),
            bigNumber: '${client.sheepCount}',
            label: 'moutons',
            subtitle: subtitle,
          ),
          const SizedBox(height: AppSpacing.md),

          // Recompute banner
          if (client.needsDistanceRecompute) ...[
            AppSectionCard(
              icon: FIcons.triangleAlert,
              iconBackground: theme.colors.destructive,
              title: 'Distances',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.clientDetailRecomputeBanner,
                      style: theme.typography.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    onPress: () async {
                      final sync = ref.read(distanceMatrixSyncProvider);
                      try {
                        await sync.recomputeForClient(client.id);
                        ref.invalidate(_clientByIdProvider(client.id));
                        ref.invalidate(clientsAsyncProvider);
                        ref.invalidate(clientsPendingProvider);
                      } on OrsException catch (e) {
                        if (context.mounted) {
                          showFToast(context: context, title: Text(e.message));
                        }
                      }
                    },
                    child: Text(l.clientDetailRetryRecompute),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Address card
          AppSectionCard(
            icon: FIcons.mapPin,
            title: l.clientDetailSectionAddress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.addressLabel,
                  style: theme.typography.md,
                ),
                Text(
                  '${client.postcode} ${client.city}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Contact card (only if phone set)
          if (client.phone != null) ...[
            AppSectionCard(
              icon: FIcons.phone,
              title: l.clientDetailSectionContact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.phone!, style: theme.typography.md),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          variant: FButtonVariant.outline,
                          prefix: const Icon(FIcons.phone),
                          onPress: () => callPhone(context, client.phone!),
                          child: const Text('Appeler'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FButton(
                          variant: FButtonVariant.outline,
                          prefix: const Icon(FIcons.messageCircle),
                          onPress: () => sendSms(context, client.phone!),
                          child: const Text('SMS'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Status section
          Builder(builder: (context) {
            final waitingToggleDisabled = status == ClientStatus.banned ||
                status == ClientStatus.noSheep ||
                status == ClientStatus.scheduled ||
                status == ClientStatus.done;
            return AppSectionCard(
              icon: FIcons.bellRing,
              title: l.clientDetailSectionStatus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FTile(
                    title: Text(l.clientStatusWaiting),
                    subtitle: waitingToggleDisabled
                        ? Text(
                            l.clientDetailWaitingDisabledHintFmt(
                              _statusLabel(l, status),
                            ),
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          )
                        : null,
                    suffix: FSwitch(
                      value: client.isWaiting,
                      onChange: waitingToggleDisabled
                          ? null
                          : (v) async {
                              await ref
                                  .read(clientRepositoryProvider)
                                  .setWaiting(id: client.id, isWaiting: v);
                              ref.invalidate(_clientByIdProvider(client.id));
                              ref.invalidate(clientsAsyncProvider);
                            },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FButton(
                    variant: client.isBanned
                        ? FButtonVariant.outline
                        : FButtonVariant.destructive,
                    prefix: Icon(client.isBanned ? FIcons.shieldOff : FIcons.ban),
                    onPress: () async {
                      await ref
                          .read(clientRepositoryProvider)
                          .setBanned(client.id, !client.isBanned);
                      ref.invalidate(_clientByIdProvider(client.id));
                      ref.invalidate(clientsAsyncProvider);
                    },
                    child: Text(
                      client.isBanned
                          ? l.clientDetailUnban
                          : l.clientDetailBan,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ResetToDefaultButton(client: client),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),

          // CTA: find nearby clients
          AppPrimaryButton(
            label: l.clientDetailFindNearby,
            prefixIcon: FIcons.compass,
            onPress: status == ClientStatus.waiting
                ? () => context.push('/proximity/${client.id}')
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

String _statusLabel(AppLocalizations l, ClientStatus status) => switch (status) {
      ClientStatus.defaultStatus => l.clientStatusDefault,
      ClientStatus.waiting => l.clientStatusWaiting,
      ClientStatus.scheduled => l.clientStatusScheduled,
      ClientStatus.done => l.clientStatusDone,
      ClientStatus.noSheep => l.clientStatusNoSheep,
      ClientStatus.banned => l.clientStatusBanned,
    };

class _ResetToDefaultButton extends ConsumerWidget {
  final Client client;
  const _ResetToDefaultButton({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    final plannedTourAsync = ref.watch(_plannedTourForClientProvider(client.id));

    return plannedTourAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tourDate) {
        final blocked = tourDate != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FButton(
              variant: FButtonVariant.outline,
              prefix: const Icon(FIcons.rotateCcw),
              onPress: blocked
                  ? null
                  : () async {
                      final repo = ref.read(clientRepositoryProvider);
                      await repo.setWaiting(id: client.id, isWaiting: false);
                      await repo.setBanned(client.id, false);
                      ref.invalidate(_clientByIdProvider(client.id));
                      ref.invalidate(clientsAsyncProvider);
                    },
              child: Text(l.clientDetailResetToDefault),
            ),
            if (blocked) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.clientDetailResetDisabledFmt(
                  DateFormat('dd/MM/yyyy').format(tourDate),
                ),
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Returns the planned date of the *earliest* tour this client is part of
/// in the current season, or null if none exists.
final _plannedTourForClientProvider =
    FutureProvider.family.autoDispose<DateTime?, int>((ref, clientId) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final db = ref.watch(appDatabaseProvider);
  final seasonEpochDays = seasonStart.millisecondsSinceEpoch ~/ 86400000;

  final rows = await (db.select(db.tourStopsTable).join([
    innerJoin(db.toursTable, db.toursTable.id.equalsExp(db.tourStopsTable.tourId)),
  ])
        ..where(
          db.tourStopsTable.clientId.equals(clientId) &
              db.toursTable.status.equals('planned') &
              db.toursTable.plannedDate.isBiggerOrEqualValue(seasonEpochDays),
        )
        ..orderBy([
          OrderingTerm.asc(db.toursTable.plannedDate),
        ])
        ..limit(1))
      .get();

  if (rows.isEmpty) return null;
  final tour = rows.first.readTable(db.toursTable);
  return DateTime.fromMillisecondsSinceEpoch(tour.plannedDate * 86400000);
});
