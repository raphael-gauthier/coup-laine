// lib/presentation/clients/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/client.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';

final _clientByIdProvider =
    FutureProvider.family<Client?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).findById(id);
});

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientByIdProvider(clientId));
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.name ?? '...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/clients/$clientId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref, l),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (c) =>
            c == null ? const SizedBox.shrink() : _Body(client: c),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l.clientDetailDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.clientDetailDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(clientRepositoryProvider).delete(clientId);
      await ref
          .read(distanceMatrixRepositoryProvider)
          .deleteForClient(clientId);
      ref.invalidate(_clientByIdProvider(clientId));
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (client.needsDistanceRecompute)
          Card(
            color: const Color(0xFFFFF3E0),
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(l.clientDetailRecomputeBanner),
              onTap: () async {
                final sync = ref.read(distanceMatrixSyncProvider);
                try {
                  await sync.recomputeForClient(client.id);
                  ref.invalidate(_clientByIdProvider(client.id));
                } on OrsException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
          ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(client.addressLabel),
          subtitle: Text('${client.postcode} ${client.city}'),
        ),
        if (client.phone != null)
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(client.phone!),
          ),
        ListTile(
          leading: const Icon(Icons.pets),
          title: Text('${client.sheepCount} moutons'),
          subtitle: client.minutesPerSheepOverride == null
              ? null
              : Text('${client.minutesPerSheepOverride} min/mouton'),
        ),
        if (client.notes != null)
          ListTile(
            leading: const Icon(Icons.note),
            title: Text(client.notes!),
          ),
        SwitchListTile(
          value: client.isWaiting,
          title: Text(l.clientDetailWaitingToggle),
          onChanged: (v) async {
            await ref
                .read(clientRepositoryProvider)
                .setWaiting(id: client.id, isWaiting: v);
            ref.invalidate(_clientByIdProvider(client.id));
          },
        ),
        const SizedBox(height: 16),
        if (client.isWaiting && !client.needsDistanceRecompute)
          FilledButton.icon(
            onPressed: () => context.push('/proximity/${client.id}'),
            icon: const Icon(Icons.travel_explore),
            label: Text(l.clientDetailFindNearby),
          ),
      ],
    );
  }
}
