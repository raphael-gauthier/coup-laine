// lib/presentation/tours/tours_list_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/tour.dart';
import '../../state/providers.dart';

final toursAsyncProvider = FutureProvider<List<Tour>>((ref) {
  return ref.watch(tourRepositoryProvider).listAll();
});

class ToursListScreen extends ConsumerWidget {
  const ToursListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(toursAsyncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.toursListTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tours) {
          if (tours.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.emptyToursTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l.emptyToursBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(toursAsyncProvider),
            child: ListView.separated(
              itemCount: tours.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = tours[i];
                return ListTile(
                  leading: Icon(
                    t.status == TourStatus.completed
                        ? Icons.check_circle
                        : Icons.alt_route,
                    color: t.status == TourStatus.completed
                        ? Colors.green
                        : null,
                  ),
                  title: Text(DateFormat('EEE dd/MM/yyyy', 'fr')
                      .format(t.plannedDate)),
                  subtitle: Text(
                    '${t.status == TourStatus.completed ? l.toursStatusCompleted : l.toursStatusPlanned} · ${(t.totalDistanceMeters / 1000).toStringAsFixed(1)} km',
                  ),
                  onTap: () => context.push('/tours/${t.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
