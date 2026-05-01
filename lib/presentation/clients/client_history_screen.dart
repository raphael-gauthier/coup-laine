import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../domain/models/intervention.dart';
import '../../state/providers.dart';
import 'manual_history_entry_sheet.dart';

class ClientHistoryScreen extends ConsumerWidget {
  final int clientId;
  const ClientHistoryScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(historyForClientProvider(clientId));

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(
          title: Text(l.clientHistoryTitle),
          suffixes: [
            FButton.icon(
              child: const Icon(FIcons.plus),
              onPress: () => showManualHistoryEntrySheet(
                context,
                clientId: clientId,
              ),
            ),
          ],
        ),
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: AppSizes.screenPadding,
                child: Text(
                  l.clientDetailHistoryEmpty,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: AppSizes.screenPadding,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final it = items[i];
                final isManual = it.kind == InterventionKind.manual;
                final dateStr =
                    DateFormat('d MMM yyyy', 'fr').format(it.date);

                // Build summary line: "{n} prestation(s) · {amount} · {duration}"
                final summaryLine = l.clientHistoryPrestationCountFmt(
                  it.prestations.length,
                  formatEuros(it.totalRevenueCents),
                  formatDuration(it.totalMinutes),
                );

                // Build detail line: up to 3 prestations
                final maxPrestaDisplay = 3;
                final displayPrestations = it.prestations.length > maxPrestaDisplay
                    ? it.prestations.sublist(0, maxPrestaDisplay)
                    : it.prestations;
                final remaining = (it.prestations.length > maxPrestaDisplay)
                    ? it.prestations.length - maxPrestaDisplay
                    : 0;

                final prestationItems = displayPrestations
                    .map((p) =>
                        '${p.nameSnapshot} ${p.categoryNameSnapshot ?? '(libre)'} × ${p.qty}')
                    .toList();

                final detailLine = prestationItems.join(' · ') +
                    (remaining > 0
                        ? ' ${l.clientHistoryAndOthersFmt(remaining)}'
                        : '');

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (it.kind == InterventionKind.tour &&
                        it.tourId != null) {
                      context.push('/tours/${it.tourId}');
                      return;
                    }
                    if (it.kind == InterventionKind.manual &&
                        it.manualEntryId != null) {
                      final manualRepo =
                          ref.read(manualHistoryRepositoryProvider);
                      final all = await manualRepo.listForClient(clientId);
                      final matches =
                          all.where((e) => e.id == it.manualEntryId);
                      final entry =
                          matches.isEmpty ? null : matches.first;
                      if (entry != null && context.mounted) {
                        await showManualHistoryEntrySheet(
                          context,
                          clientId: clientId,
                          existing: entry,
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: AppSizes.listTilePadding,
                    decoration: BoxDecoration(
                      color: theme.colors.card,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: theme.colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isManual ? FIcons.pencil : FIcons.scissors,
                          size: 20,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: theme.typography.md.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colors.foreground,
                                ),
                              ),
                              Text(
                                summaryLine,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              Text(
                                detailLine,
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!it.hasBilan)
                                Text(
                                  l.clientDetailHistoryNoBilan.trim(),
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (it.note != null && it.note!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  it.note!,
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
