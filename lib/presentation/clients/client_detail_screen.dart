// lib/presentation/clients/client_detail_screen.dart
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/client.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import 'clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;

final _clientByIdProvider = FutureProvider.family<Client?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).findById(id);
});

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientByIdProvider(clientId));
    final l = AppLocalizations.of(context)!;

    return FScaffold(
      header: FHeader.nested(
        title: Text(async.value?.name ?? '...'),
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
        data: (c) => c == null ? const SizedBox.shrink() : _Body(client: c),
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
  const _Body({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    final lastShearingText = client.lastShearingDate == null
        ? l.clientsLastShearingNever
        : l.clientsLastShearingFmt(
            DateFormat('dd/MM/yyyy').format(client.lastShearingDate!),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card: sheep count
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${client.sheepCount}',
                        style: theme.typography.xl4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.clientDetailSheepCountFmt(client.sheepCount)
                            .replaceFirst('${client.sheepCount} ', ''),
                        style: theme.typography.lg.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastShearingText,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  if (client.minutesPerSheepOverride != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${client.minutesPerSheepOverride} min/mouton',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Recompute banner
          if (client.needsDistanceRecompute) ...[
            FCard(
              child: Row(
                children: [
                  Icon(FIcons.triangleAlert, color: theme.colors.destructive, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.clientDetailRecomputeBanner,
                      style: theme.typography.sm,
                    ),
                  ),
                  const SizedBox(width: 8),
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
            const SizedBox(height: 12),
          ],

          // Address card
          FCard(
            title: Text(l.clientDetailSectionAddress),
            child: FTile(
              prefix: const Icon(FIcons.mapPin),
              title: Text(client.addressLabel),
              subtitle: Text('${client.postcode} ${client.city}'),
            ),
          ),
          const SizedBox(height: 12),

          // Contact card (only if phone set)
          if (client.phone != null) ...[
            FCard(
              title: Text(l.clientDetailSectionContact),
              child: FTile(
                prefix: const Icon(FIcons.phone),
                title: Text(client.phone!),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Notes card (only if notes set)
          if (client.notes != null) ...[
            FCard(
              title: Text(l.clientDetailSectionNotes),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  client.notes!,
                  style: theme.typography.md.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Status section
          FCard(
            title: Text(l.clientDetailSectionStatus),
            child: FTile(
              prefix: const Icon(FIcons.clock),
              title: Text(l.clientDetailWaitingToggle),
              suffix: FSwitch(
                value: client.isWaiting,
                onChange: (v) async {
                  await ref
                      .read(clientRepositoryProvider)
                      .setWaiting(id: client.id, isWaiting: v);
                  ref.invalidate(_clientByIdProvider(client.id));
                  ref.invalidate(clientsAsyncProvider);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // CTA: find nearby clients
          FButton(
            onPress: (client.isWaiting && !client.needsDistanceRecompute)
                ? () => context.push('/proximity/${client.id}')
                : null,
            prefix: const Icon(FIcons.compass),
            child: Text(l.clientDetailFindNearby),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
