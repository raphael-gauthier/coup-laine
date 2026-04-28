// lib/presentation/clients/clients_list_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/client.dart';
import '../../state/providers.dart';

enum _Filter { all, waiting }

final _filterProvider = StateProvider<_Filter>((_) => _Filter.all);

final _clientsAsyncProvider = FutureProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).listAll();
});

final _pendingProvider = FutureProvider<int>((ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  return (await clients.listNeedingRecompute()).length;
});

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final filter = ref.watch(_filterProvider);
    final async = ref.watch(_clientsAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.clientsListTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<_Filter>(
              segments: [
                ButtonSegment(
                    value: _Filter.all, label: Text(l.clientsFilterAll)),
                ButtonSegment(
                    value: _Filter.waiting,
                    label: Text(l.clientsFilterWaiting)),
              ],
              selected: {filter},
              onSelectionChanged: (s) =>
                  ref.read(_filterProvider.notifier).state = s.first,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.add),
        label: Text(l.clientsAddNew),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final list = filter == _Filter.waiting
              ? all.where((c) => c.isWaiting).toList()
              : all;
          final pending = ref.watch(_pendingProvider).value ?? 0;
          return Column(
            children: [
              if (pending > 0)
                MaterialBanner(
                  content: Text('$pending client(s) sans distances calculées'),
                  leading: const Icon(Icons.warning_amber),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        final sync = ref.read(distanceMatrixSyncProvider);
                        final fixed = await sync.retryAllPending();
                        ref.invalidate(_pendingProvider);
                        ref.invalidate(_clientsAsyncProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$fixed client(s) recalculés'),
                            ),
                          );
                        }
                      },
                      child: const Text('Recalculer'),
                    ),
                  ],
                ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.emptyClientsTitle,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(l.emptyClientsBody,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(_clientsAsyncProvider);
                          ref.invalidate(_pendingProvider);
                        },
                        child: ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) =>
                              _ClientTile(client: list[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lastShearing = client.lastShearingDate == null
        ? l.clientsLastShearingNever
        : l.clientsLastShearingFmt(
            DateFormat('dd/MM/yyyy').format(client.lastShearingDate!),
          );
    return ListTile(
      title: Text(client.name),
      subtitle: Text('${client.city} · $lastShearing'),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (client.isWaiting)
            const Chip(
                label: Text('En attente'),
                visualDensity: VisualDensity.compact),
          if (client.needsDistanceRecompute)
            const Chip(
                label: Text('Distances'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Color(0xFFFFE0B2)),
        ],
      ),
      onTap: () => context.push('/clients/${client.id}'),
    );
  }
}
