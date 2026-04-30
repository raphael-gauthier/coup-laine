import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
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
                final dateStr = DateFormat('dd/MM/yyyy').format(it.date);
                final main = l.clientDetailHistoryItemFmt(
                    dateStr, it.small, it.large);
                final isManual = it.kind == InterventionKind.manual;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: main,
                                style: theme.typography.md.copyWith(
                                  color: theme.colors.foreground,
                                ),
                              ),
                              if (isManual)
                                TextSpan(
                                  text: ' · ${l.clientHistoryManualBadge}',
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (!it.hasBilan)
                                TextSpan(
                                  text: l.clientDetailHistoryNoBilan,
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (it.note != null && it.note!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            it.note!,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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
