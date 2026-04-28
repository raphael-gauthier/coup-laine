// lib/presentation/map/client_pin_popup.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../clients/client_actions.dart';

class ClientPinPopup extends StatelessWidget {
  final Client client;
  final VoidCallback onOpenDetail;

  const ClientPinPopup({
    super.key,
    required this.client,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasPhone = client.phone != null && client.phone!.trim().isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenDetail,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260, minWidth: 200),
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
                    style: theme.typography.md.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  FIcons.chevronRight,
                  size: 18,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${client.city} · ${client.sheepCount} moutons',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    prefix: const Icon(FIcons.phone),
                    onPress:
                        hasPhone ? () => callPhone(context, client.phone!) : null,
                    child: const Text('Appeler'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    prefix: const Icon(FIcons.messageCircle),
                    onPress:
                        hasPhone ? () => sendSms(context, client.phone!) : null,
                    child: const Text('SMS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
