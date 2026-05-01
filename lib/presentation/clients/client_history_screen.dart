import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format_minutes.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/client.dart';
import '../../domain/models/intervention.dart';
import '../../state/providers.dart';
import '../../state/providers/client_kpis.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_timeline_row.dart';
import 'manual_history_entry_sheet.dart';

final _clientByIdProvider =
    FutureProvider.autoDispose.family<Client?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).findById(id);
});

// ── flat list item types ──────────────────────────────────────────────────────

class _MonthHeader {
  final String label;
  const _MonthHeader(this.label);
}

class _Entry {
  final Intervention intervention;
  const _Entry(this.intervention);
}

// ── helpers ───────────────────────────────────────────────────────────────────

String _relativeShort(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays < 30) return 'il y a ${diff.inDays}j';
  final m = (diff.inDays / 30).round();
  if (m < 12) return 'il y a ${m}m';
  final y = (m / 12).round();
  return 'il y a ${y}an${y > 1 ? 's' : ''}';
}

String _breakdown(Intervention it, AppLocalizations l) {
  final parts = <String>[];
  for (final p in it.prestations) {
    parts.add('${p.qty} ${p.nameSnapshot}');
    if (parts.length >= 3) break;
  }
  if (it.prestations.length > 3) {
    parts.add(l.clientHistoryAndOthersFmt(it.prestations.length - 3));
  }
  return parts.join(' · ');
}

List<Object> _buildFlatList(List<Intervention> items) {
  final sorted = [...items]..sort((a, b) => b.date.compareTo(a.date));
  final out = <Object>[];
  String? currentMonth;
  final fmt = DateFormat('MMMM yyyy', 'fr');
  for (final it in sorted) {
    final monthKey = fmt.format(it.date).toUpperCase();
    if (monthKey != currentMonth) {
      out.add(_MonthHeader(monthKey));
      currentMonth = monthKey;
    }
    out.add(_Entry(it));
  }
  return out;
}

// ── screen ────────────────────────────────────────────────────────────────────

class ClientHistoryScreen extends ConsumerWidget {
  final int clientId;
  const ClientHistoryScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final clientAsync = ref.watch(_clientByIdProvider(clientId));
    final kpisAsync = ref.watch(clientKpisProvider(clientId));
    final historyAsync = ref.watch(historyForClientProvider(clientId));

    // Derive title / subtitle from client + history
    final clientName = clientAsync.asData?.value?.name ?? '…';
    final interventionCount = kpisAsync.asData?.value.interventionCount ?? 0;
    final subtitle = '$interventionCount intervention${interventionCount > 1 ? 's' : ''}';

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: l.clientHistoryTitleFmt(clientName),
              subtitle: subtitle,
            ),
            // KPI row — shown once kpis are available
            kpisAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (kpis) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AppKpiRow(
                  cells: [
                    AppKpiCell(
                      value: '${kpis.interventionCount}',
                      label: l.kpiLabelInterventions,
                    ),
                    AppKpiCell(
                      value: formatEuros(kpis.totalRevenueCents),
                      label: l.kpiLabelRevenue,
                    ),
                    AppKpiCell(
                      value: kpis.lastInterventionDate != null
                          ? _relativeShort(kpis.lastInterventionDate!)
                          : '–',
                      label: l.kpiLabelLastVisit,
                    ),
                  ],
                ),
              ),
            ),
            // History list
            Expanded(
              child: Stack(
                children: [
                  historyAsync.when(
                    loading: () =>
                        const Center(child: FCircularProgress()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Text(l.clientDetailHistoryEmpty),
                        );
                      }
                      final flat = _buildFlatList(items);
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: flat.length,
                        itemBuilder: (_, i) {
                          final item = flat[i];
                          if (item is _MonthHeader) {
                            return _MonthHeaderTile(label: item.label);
                          }
                          final entry = item as _Entry;
                          final it = entry.intervention;
                          return AppTimelineRow(
                            dateLabel:
                                DateFormat('d MMM', 'fr').format(it.date),
                            icon: it.kind == InterventionKind.manual
                                ? FIcons.pencil
                                : FIcons.scissors,
                            title: it.kind == InterventionKind.tour
                                ? l.clientHistoryKindTour
                                : l.clientHistoryKindManual,
                            breakdown: _breakdown(it, l),
                            amount: it.totalRevenueCents == 0
                                ? null
                                : formatEuros(it.totalRevenueCents),
                            duration: it.totalMinutes == 0
                                ? null
                                : formatDuration(it.totalMinutes),
                            onTap: () => _onTap(context, ref, it),
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: AppFAB(
                      icon: FIcons.plus,
                      label: l.clientHistoryAddAction,
                      extended: true,
                      onPress: () => showManualHistoryEntrySheet(
                        context,
                        clientId: clientId,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(
      BuildContext context, WidgetRef ref, Intervention it) async {
    if (it.kind == InterventionKind.tour && it.tourId != null) {
      context.push('/tours/${it.tourId}');
      return;
    }
    if (it.kind == InterventionKind.manual && it.manualEntryId != null) {
      final manualRepo = ref.read(manualHistoryRepositoryProvider);
      final all = await manualRepo.listForClient(clientId);
      final matches = all.where((e) => e.id == it.manualEntryId);
      final entry = matches.isEmpty ? null : matches.first;
      if (entry != null && context.mounted) {
        await showManualHistoryEntrySheet(
          context,
          clientId: clientId,
          existing: entry,
        );
      }
    }
  }
}

// ── month header tile ─────────────────────────────────────────────────────────

class _MonthHeaderTile extends StatelessWidget {
  final String label;
  const _MonthHeaderTile({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: captionStyle(theme.typography.xs).copyWith(
          color: theme.colors.mutedForeground,
        ),
      ),
    );
  }
}
