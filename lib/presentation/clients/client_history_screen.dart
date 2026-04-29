import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/intervention.dart';
import '../../state/providers.dart';

final _historyForClientProvider =
    FutureProvider.family.autoDispose<List<Intervention>, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).listInterventionsForClient(id);
});

class ClientHistoryScreen extends ConsumerWidget {
  final int clientId;
  const ClientHistoryScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(_historyForClientProvider(clientId));

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.clientHistoryTitle)),
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
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/tours/${it.tourId}'),
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
