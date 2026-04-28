// lib/presentation/clients/client_detail_screen.dart
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import 'client_actions.dart';
import '../../domain/models/client.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_hero_card.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
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
            badge: client.isWaiting ? AppBadge.waiting(context) : null,
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

          // Notes card (only if notes set)
          if (client.notes != null) ...[
            AppSectionCard(
              icon: FIcons.notebookPen,
              title: l.clientDetailSectionNotes,
              child: Text(
                client.notes!,
                style: theme.typography.md.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Status section
          AppSectionCard(
            icon: FIcons.bellRing,
            title: l.clientDetailSectionStatus,
            child: FTile(
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
          const SizedBox(height: AppSpacing.lg),

          // CTA: find nearby clients
          AppPrimaryButton(
            label: l.clientDetailFindNearby,
            prefixIcon: FIcons.compass,
            onPress: (client.isWaiting && !client.needsDistanceRecompute)
                ? () => context.push('/proximity/${client.id}')
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
