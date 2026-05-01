// lib/presentation/map/client_pin_popup.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../../domain/use_cases/client_status.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/animal_counts_badges.dart';
import '../widgets/app_badge.dart';

class ClientPinPopup extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  final VoidCallback onOpenDetail;

  const ClientPinPopup({
    super.key,
    required this.client,
    required this.status,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l = AppLocalizations.of(context)!;
    final distanceAsync = ref.watch(clientDistanceFromBaseProvider(client.id));

    final lastInterventionLabel = client.lastInterventionDate == null
        ? l.clientsLastInterventionNever
        : l.clientsLastInterventionFmt(
            DateFormat('d MMM yyyy', 'fr').format(client.lastInterventionDate!),
          );

    final addressLine = StringBuffer('${client.postcode} ${client.city}');
    final distanceMeters = distanceAsync.asData?.value;
    if (distanceMeters != null && distanceMeters > 0) {
      final km = (distanceMeters / 1000).round();
      addressLine.write(' · $km km');
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenDetail,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280, minWidth: 220),
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: theme.colors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0x33000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.md.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppBadge.fromStatus(
                  context,
                  status: status,
                  label: _statusLabel(l, status),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  FIcons.chevronRight,
                  size: 18,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              addressLine.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            if (client.animals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: AnimalCountsBadges(
                  counts: client.animals,
                  mode: AnimalCountsBadgesMode.compact,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                lastInterventionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    prefix: const Icon(FIcons.compass),
                    onPress: () => _openItinerary(client),
                    child: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    prefix: const Icon(FIcons.route),
                    onPress: () => context.push('/proximity/${client.id}'),
                    child: const Text('Planifier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openItinerary(Client c) async {
    // Universal "geo:" URI — handled by Maps/Waze/etc.
    final uri = Uri.parse(
      'geo:${c.coordinates.lat},${c.coordinates.lon}?q=${c.coordinates.lat},${c.coordinates.lon}(${Uri.encodeComponent(c.name)})',
    );
    await launchUrl(uri);
  }

  String _statusLabel(AppLocalizations l, ClientStatus s) => switch (s) {
        ClientStatus.defaultStatus => l.clientStatusDefault,
        ClientStatus.waiting => l.clientStatusWaiting,
        ClientStatus.scheduled => l.clientStatusScheduled,
        ClientStatus.done => l.clientStatusDone,
        ClientStatus.noAnimals => l.clientStatusNoAnimals,
        ClientStatus.banned => l.clientStatusBanned,
      };
}
